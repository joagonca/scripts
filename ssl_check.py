import ssl
import socket
import datetime
import sys

def check_ssl_expiration(endpoint):
    """
    Checks the SSL certificate for a given endpoint and returns the number of days until it expires.

    Args:
        endpoint (str): The endpoint to check (e.g., "www.google.com").

    Returns:
        int: The number of days until the certificate expires.  Returns -1 if the certificate is already expired.
             Returns -2 if there's an error connecting or retrieving the certificate.
    """
    try:
        context = ssl.create_default_context()
        with socket.create_connection((endpoint, 443)) as sock:
            with context.wrap_socket(sock, server_hostname=endpoint) as ssock:
                cert = ssock.getpeercert()
                if cert is None:
                    return -2  # Could not retrieve certificate

                not_after_str = cert['notAfter']
                not_after_date = datetime.datetime.strptime(not_after_str, "%b %d %H:%M:%S %Y %Z")
                now = datetime.datetime.now()
                
                days_until_expiration = (not_after_date - now).days

                if days_until_expiration < 0:
                    return -1  # Certificate has expired
                else:
                    return days_until_expiration

    except socket.gaierror:
        return -2  # Hostname could not be resolved
    except socket.error:
        return -2  # Connection error
    except ssl.SSLError:
        return -2  # SSL error
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return -2 # Other errors


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_ssl.py <endpoint>")
        sys.exit(1)

    endpoint = sys.argv[1]
    days_until_expiration = check_ssl_expiration(endpoint)
    print(f"{days_until_expiration}")
