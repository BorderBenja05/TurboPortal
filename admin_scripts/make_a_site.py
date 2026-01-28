import requests
import time
import os
from dotenv import load_dotenv
load_dotenv()

url = "http://localhost:8000/api/telescope"

token = f'token {os.environ['API_KEY']}'


headers = {
            # "Content-Type": "application/json",
            "Authorization": token
           }

# for i in range(12):
#     data = {
#         "name": f"New Mexico {i+1}",
#         "nickname": f"NM {i+1}",
#         "lat": 33.9789 + (i*0.0001),
#         "lon": -107.187184,
#         "elevation": 3230.9,
#         "diameter": 0.2794,
#         "robotic": True,
#         "fixed_location": True
#     }

#     response = requests.post(url, json=data,  headers=headers)
#     time.sleep(1)

#     print(response.json())




data = {
    "name": f"Multiple Mirror Telescope",
    "nickname": f"MMT",
    "lat": 31.689081,
    "lon": -110.885148,
    "elevation": 2616,
    "diameter": 6.5,
    "robotic": True,
    "fixed_location": True
}

response = requests.post(url, json=data,  headers=headers)
time.sleep(1)

print(response.json())