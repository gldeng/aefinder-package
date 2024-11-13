PYTHON_SCRIPT = '''
import requests
import json
import os
import sys
import traceback
import logging
from http.client import HTTPConnection

# Add these lines at the beginning of the script, after the imports
# Set up logging
logging.basicConfig(level=logging.DEBUG)

# Enable HTTP request logging
HTTPConnection.debuglevel = 1

# Create a custom logger for requests
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True


class AeFinderClientBase:
    def __init__(
        self,
        authserver_url,
        api_url,
        appuser_username,
        appuser_password,
    ):
        self.authserver_url = authserver_url
        self.api_url = api_url
        self.appuser_username = appuser_username
        self.appuser_password = appuser_password
        self._org_id = None

    def _get_user_token(self):
        token_url = f"{self.authserver_url}/connect/token"
        token_data = {
            'grant_type': 'password',
            'scope': 'AeFinder',
            'username': self.appuser_username,
            'password': self.appuser_password,
            'client_id': 'AeFinder_App'
        }
        token_response = requests.post(token_url, data=token_data)
        user_token = token_response.json()['access_token']
        return user_token

class AeFinderClient(AeFinderClientBase):
    def __init__(
        self,
        authserver_url,
        api_url,
        root_username,
        root_password,
        org_name,
        appuser_username,
        appuser_password,
        appuser_email
    ):
        super().__init__(authserver_url, api_url, appuser_username, appuser_password)
        self.root_username = root_username
        self.root_password = root_password
        self.org_name = org_name
        self.appuser_email = appuser_email

    @property
    def org_id(self):
        if self._org_id is None:
            self._org_id = self._create_organization()
        return self._org_id

    def _get_admin_token(self):
        token_url = f"{self.authserver_url}/connect/token"
        token_data = {
            'grant_type': 'password',
            'scope': 'AeFinder',
            'username': self.root_username,
            'password': self.root_password,
            'client_id': 'AeFinder_App'
        }
        token_response = requests.post(token_url, data=token_data)
        admin_token = token_response.json()['access_token']        
        return admin_token

    def _create_organization(self):
        admin_token = self._get_admin_token()
        org_url = f"{self.api_url}/api/organizations"    
        org_data = {"displayName": self.org_name}
        org_headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {admin_token}'
        }
        org_response = requests.post(org_url, headers=org_headers, json=org_data)
        organization_id = org_response.json()['id']
        return organization_id

    def _create_user(self):
        admin_token = self._get_admin_token()
        user_url = f"{self.api_url}/api/users"
        user_data = {
            "username": self.appuser_username,
            "password": self.appuser_password,
            "email": self.appuser_email,
            "organizationUnitId": self.org_id
        }
        user_headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {admin_token}'
        }
        user_response = requests.post(user_url, headers=user_headers, json=user_data)
        return user_response.json()

    def create_org_and_user(self):
        organization_id = self.org_id
        self._create_user()


if __name__ == "__main__":
    try:
        if len(sys.argv) != 9:
            raise ValueError("Incorrect number of arguments provided.")
        
        client = AeFinderClient(
            authserver_url=sys.argv[1],
            api_url=sys.argv[2],
            root_username=sys.argv[3],
            root_password=sys.argv[4],
            org_name=sys.argv[5],
            appuser_username=sys.argv[6],
            appuser_password=sys.argv[7],
            appuser_email=sys.argv[8]
        )
        client.create_org_and_user()
        
        # Ensure the directory exists
        os.makedirs('/tmp', exist_ok=True)
        
        # Write the org_id to the file
        with open('/tmp/org_id.txt', 'w') as f:
            f.write(str(client.org_id))
        
        # Print the file contents and location for debugging
        print(f"org_id written to /tmp/org_id.txt: {client.org_id}")
        print(f"File contents: {open('/tmp/org_id.txt', 'r').read()}")
        print(f"Files in /tmp: {os.listdir('/tmp')}")
        
    except Exception as e:
        print(f"An error occurred: {str(e)}", file=sys.stderr)
        print("Traceback:", file=sys.stderr)
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)
'''


DEFAULT_ROOT_USERNAME = "admin"
DEFAULT_ROOT_PASSWORD = "1q2W3e*"
DEFAULT_ORG_NAME = "testorg"
DEFAULT_APPUSER_USERNAME = "testuser"
DEFAULT_APPUSER_PASSWORD = "aBcD@123"
DEFAULT_APPUSER_EMAIL = "dev@test.example"
ORG_ID_ARTIFACT_NAME = "org_id"


def create_org_and_user(
    plan,
    authserver_url,
    api_url,
    org_name = DEFAULT_ORG_NAME,
    appuser_username = DEFAULT_APPUSER_USERNAME,
    appuser_password = DEFAULT_APPUSER_PASSWORD,
    appuser_email = DEFAULT_APPUSER_EMAIL,
    root_username = DEFAULT_ROOT_USERNAME,
    root_password = DEFAULT_ROOT_PASSWORD,
):
    result = plan.run_python(
        run=PYTHON_SCRIPT,
        image = "python:3.11-alpine",
        packages = [
            "requests"
        ],
        args= [
            authserver_url,
            api_url,
            root_username,
            root_password,
            org_name,
            appuser_username,
            appuser_password,
            appuser_email,
        ],
        store = [
            StoreSpec(src = "/tmp/org_id.txt", name = ORG_ID_ARTIFACT_NAME),
        ]
    )
    return result.files_artifacts
