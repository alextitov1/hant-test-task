"""
FastAPI application that displays AWS EC2 instance information.

This application runs on an EC2 instance and provides both HTML and JSON
endpoints to display instance metadata, tags, state, and resource usage.
"""

import json
import logging
from typing import Dict, Optional
from datetime import datetime

import boto3
import psutil
import requests
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
from botocore.exceptions import ClientError, BotoCoreError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="EC2 Instance Info API",
    description="API to retrieve EC2 instance information",
    version="1.0.0"
)

# Initialize Jinja2 templates
templates = Jinja2Templates(directory="app/templates")

# IMDSv2 token TTL in seconds
IMDS_TOKEN_TTL = 21600  # 6 hours


def get_imds_token() -> Optional[str]:
    """
    Get IMDSv2 token for secure metadata access.
    
    Returns:
        str: IMDSv2 token or None if failed
    """
    try:
        token_url = "http://169.254.169.254/latest/api/token"
        response = requests.put(
            token_url,
            headers={"X-aws-ec2-metadata-token-ttl-seconds": str(IMDS_TOKEN_TTL)},
            timeout=2
        )
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        logger.error(f"Failed to get IMDSv2 token: {e}")
        return None


def get_instance_metadata() -> Dict[str, Optional[str]]:
    """
    Retrieve instance metadata using IMDSv2.
    
    Returns:
        dict: Instance metadata including instance_id, region, private_ip, public_ip
    """
    token = get_imds_token()
    if not token:
        logger.warning("Failed to get IMDSv2 token, returning empty metadata")
        return {
            "instance_id": None,
            "region": None,
            "availability_zone": None,
            "private_ip": None,
            "public_ip": None,
            "instance_type": None,
        }
    
    headers = {"X-aws-ec2-metadata-token": token}
    base_url = "http://169.254.169.254/latest/meta-data"
    
    metadata = {}
    
    # Fetch various metadata fields
    endpoints = {
        "instance_id": f"{base_url}/instance-id",
        "instance_type": f"{base_url}/instance-type",
        "availability_zone": f"{base_url}/placement/availability-zone",
        "private_ip": f"{base_url}/local-ipv4",
        "public_ip": f"{base_url}/public-ipv4",
    }
    
    for key, url in endpoints.items():
        try:
            response = requests.get(url, headers=headers, timeout=2)
            if response.status_code == 200:
                metadata[key] = response.text
            else:
                metadata[key] = None
        except requests.RequestException as e:
            logger.warning(f"Failed to fetch {key}: {e}")
            metadata[key] = None
    
    # Extract region from availability zone
    if metadata.get("availability_zone"):
        metadata["region"] = metadata["availability_zone"][:-1]
    else:
        metadata["region"] = None
    
    return metadata


def get_instance_tags_and_state(instance_id: str, region: str) -> Dict:
    """
    Get instance tags and state using boto3 EC2 API.
    
    Args:
        instance_id: EC2 instance ID
        region: AWS region
        
    Returns:
        dict: Instance tags and state information
    """
    if not instance_id or not region:
        return {"tags": {}, "state": "unknown"}
    
    try:
        ec2_client = boto3.client('ec2', region_name=region)
        
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        
        if not response['Reservations']:
            return {"tags": {}, "state": "unknown"}
        
        instance = response['Reservations'][0]['Instances'][0]
        
        # Extract tags
        tags = {}
        for tag in instance.get('Tags', []):
            tags[tag['Key']] = tag['Value']
        
        # Extract state
        state = instance['State']['Name']
        
        return {"tags": tags, "state": state}
        
    except (ClientError, BotoCoreError) as e:
        logger.error(f"Failed to get instance tags and state: {e}")
        return {"tags": {}, "state": "error"}
    except Exception as e:
        logger.error(f"Unexpected error getting instance info: {e}")
        return {"tags": {}, "state": "error"}


def get_resource_usage() -> Dict[str, float]:
    """
    Get current CPU and memory usage using psutil.
    
    Returns:
        dict: CPU and memory usage percentages
    """
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        memory_percent = memory.percent
        
        return {
            "cpu_usage_percent": round(cpu_percent, 2),
            "memory_usage_percent": round(memory_percent, 2)
        }
    except Exception as e:
        logger.error(f"Failed to get resource usage: {e}")
        return {
            "cpu_usage_percent": 0.0,
            "memory_usage_percent": 0.0
        }


def get_all_instance_info() -> Dict:
    """
    Gather all instance information.
    
    Returns:
        dict: Complete instance information
    """
    # Get metadata
    metadata = get_instance_metadata()
    
    # Get tags and state
    instance_id = metadata.get("instance_id")
    region = metadata.get("region")
    tags_and_state = get_instance_tags_and_state(instance_id, region)
    
    # Get resource usage
    resource_usage = get_resource_usage()
    
    # Combine all information
    instance_info = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "instance_id": metadata.get("instance_id"),
        "instance_type": metadata.get("instance_type"),
        "instance_state": tags_and_state.get("state"),
        "region": metadata.get("region"),
        "availability_zone": metadata.get("availability_zone"),
        "private_ip": metadata.get("private_ip"),
        "public_ip": metadata.get("public_ip"),
        "tags": tags_and_state.get("tags", {}),
        "cpu_usage_percent": resource_usage.get("cpu_usage_percent"),
        "memory_usage_percent": resource_usage.get("memory_usage_percent"),
    }
    
    return instance_info


@app.get("/health")
async def health_check():
    """
    Health check endpoint.
    
    Returns:
        dict: Health status
    """
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat() + "Z"}


@app.get("/instance-info")
async def instance_info_json():
    """
    Get instance information as JSON.
    
    Returns:
        JSONResponse: Complete instance information
    """
    try:
        info = get_all_instance_info()
        return JSONResponse(content=info)
    except Exception as e:
        logger.error(f"Error getting instance info: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/", response_class=HTMLResponse)
async def instance_info_html(request: Request):
    """
    Get instance information as HTML page.
    
    Args:
        request: FastAPI request object
        
    Returns:
        HTMLResponse: Rendered HTML page with instance information
    """
    try:
        info = get_all_instance_info()
        return templates.TemplateResponse(
            "index.html",
            {"request": request, "info": info}
        )
    except Exception as e:
        logger.error(f"Error rendering HTML page: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
