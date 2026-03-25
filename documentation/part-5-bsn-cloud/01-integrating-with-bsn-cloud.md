# Chapter 13: Integrating with BSN.cloud

[← Back to Part 5: BSN Cloud](README.md) | [↑ Main](../../README.md)

---

## Introduction

BSN.cloud (BrightSign Network cloud) is BrightSign's cloud-based device control platform. It provides a comprehensive solution for managing digital signage networks at scale, from single installations to enterprise deployments with thousands of players. This chapter covers BSN.cloud integration, including provisioning, remote control, and API-based automation.

## BSN.cloud Overview

### Cloud Architecture

BSN.cloud uses a distributed cloud architecture with the following components:

- **Control Plane**: Manages device registration, authentication, and command distribution
- **Content Delivery Network (CDN)**: Delivers media files and presentations to players
- **API Layer**: RESTful APIs for programmatic access to all platform features
- **Database Layer**: Stores device configurations, content metadata, and analytics
- **WebSocket Gateway**: Enables real-time communication with connected devices

The architecture supports high availability and scales to accommodate networks of any size.

### Service Tiers and Features

BSN.cloud offers multiple service tiers:

**bsn.Control** (Free tier):
- Basic device provisioning and activation
- Remote diagnostics and control
- Device health monitoring
- Limited API access for device management
- B-Deploy automated provisioning

**bsn.Content** (Paid subscription):

Content management, presentations, and scheduling are documented in the purplecontent docs at `/external/purplecontent/docs`.

**Enterprise**:
- Custom SLA agreements
- Advanced security features
- White-label options
- Premium support options?

### Account Setup

To get started with BSN.cloud:

1. Create an account at https://www.bsn.cloud
2. Verify your email address
3. Choose a service tier
4. Create your first network
5. Obtain API credentials (for programmatic access)

For API access, you'll need client credentials:

```javascript
// Request client credentials from BrightSign support
// Credentials include:
{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret"
}
```

### Organization Structure

BSN.cloud uses a hierarchical organization model:

- **Person**: Individual user account with email/password credentials
- **Network**: Container for players, content, and presentations
  - A network can have multiple users with different permission levels
  - Players belong to exactly one network at a time
  - Network creator becomes the administrator
- **Groups**: Logical collections of players for targeted deployments
- **Roles**: Define permissions for users within a network

### User Management

Manage users through the BSN.cloud web interface or REST API:

```http
GET /2020/10/REST/Users/
```

Users can have various permission levels:
- **Administrator**: Full network access
- **Contributor**: Can create and modify content
- **Viewer**: Read-only access
- **Custom Roles**: Fine-grained permission control

## Device Provisioning

### Player Registration

Players can be registered through multiple methods:

**Manual Registration** (Web UI):
1. Log into BSN.cloud
2. Navigate to Devices section
3. Click "Add Device"
4. Enter serial number
5. Configure device settings

**API-Based Registration**:

```javascript
// Register a device using REST API
async function registerDevice(serialNumber, networkId, accessToken) {
  const response = await fetch('https://api.bsn.cloud/2020/10/REST/Devices', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      serial: serialNumber,
      name: `Player-${serialNumber}`,
      description: 'Digital signage player',
      // Additional device configuration
    })
  });

  return await response.json();
}
```

### Activation Process

When a BrightSign player boots without local content:

1. Player displays on-screen activation interface
2. User can enter activation code or wait for auto-provisioning
3. Player contacts BSN.cloud activation servers
4. If serial number is registered, player downloads setup package
5. Player configures itself and downloads assigned presentation
6. Player begins playback and maintains cloud connection

### Network Configuration

Configure network settings via Device Setup packages or API:

```javascript
// Configure network interface settings
const networkSettings = {
  networkInterfaces: [
    {
      interfaceType: 'ethernet',
      interfaceName: 'eth0',
      dhcp: true,
      metric: 100  // Interface priority (lower = higher priority)
    },
    {
      interfaceType: 'wifi',
      interfaceName: 'wlan0',
      dhcp: true,
      ssid: 'YourNetwork',
      passphrase: 'YourPassword',
      metric: 110
    }
  ]
};
```

Starting with BrightSignOS 8.4.6, interface metrics are automatically assigned:
- Metric = (interface_index × 10) + 100
- Lower metrics have higher priority
- Range 100-199 reserved for BSN-managed interfaces

### Security Certificates

BSN.cloud uses TLS certificates for secure communication:

- **Server Certificates**: BSN.cloud uses industry-standard CA certificates
- **Client Authentication**: Players authenticate using OAuth2 device credentials
- **Certificate Pinning**: Optional for enhanced security in sensitive deployments

### Bulk Provisioning

For large deployments, use B-Deploy API:

```javascript
// Bulk register devices
async function bulkRegisterDevices(serialNumbers, setupId, accessToken) {
  const devices = serialNumbers.map(serial => ({
    serialNumber: serial,
    deviceSetupId: setupId
  }));

  const response = await fetch('https://api.bdeploy.bsn.cloud/devices/bulk', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ devices })
  });

  return await response.json();
}
```

## Device Management

### Remote Monitoring

Monitor device status via API:

```javascript
// Get device status
async function getDeviceStatus(deviceId, accessToken) {
  const response = await fetch(
    `https://api.bsn.cloud/2020/10/REST/Devices/${deviceId}/`,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Accept': 'application/json'
      }
    }
  );

  const device = await response.json();

  // Device status includes:
  // - lastCheckIn: Last communication time
  // - firmwareVersion: Current OS version
  // - model: Player model
  // - networkInterfaces: Network configuration and status
  // - storage: Storage capacity and usage
  // - currentPresentation: Active presentation

  return device;
}
```

### Health Checks

BSN.cloud performs automated health checks:

- **Connectivity**: Device online/offline status
- **Storage**: Available storage space
- **Temperature**: Device operating temperature (if supported)
- **Playback**: Current playback status
- **Errors**: Error logs and diagnostics

### Diagnostics

Access detailed diagnostic information:

```javascript
// Get device errors
async function getDeviceErrors(deviceId, accessToken) {
  const response = await fetch(
    `https://api.bsn.cloud/2020/10/REST/Devices/${deviceId}/Errors/`,
    {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    }
  );

  const errors = await response.json();
  return errors;
}
```

### Remote Snapshots

Capture screenshots remotely:

```javascript
// Retrieve latest screenshot
async function getDeviceScreenshot(deviceId, accessToken) {
  const response = await fetch(
    `https://api.bsn.cloud/2020/10/REST/Devices/${deviceId}/ScreenShots/`,
    {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    }
  );

  const screenshots = await response.json();
  // Returns array of screenshot entities with URLs
  return screenshots;
}
```

### Log Collection

Retrieve device logs for troubleshooting:

- **System Logs**: OS-level logs
- **Application Logs**: BrightSign software logs
- **Error Logs**: Captured errors and exceptions
- **Network Logs**: Network activity logs

Access via Remote DWS (Diagnostic Web Server) API.

## Network APIs

### REST API Overview

BSN.cloud provides comprehensive REST APIs:

**Base URLs**:
- Main API: `https://api.bsn.cloud/2020/10/REST/`
- B-Deploy API: `https://api.bdeploy.bsn.cloud/`
- Remote DWS: Dynamically assigned per device

**API Versions**:
- 2020/10: Stable, widely supported
- 2022/06: Enhanced features, recommended for new integrations

### Authentication

BSN.cloud uses OAuth2 client credentials flow for authentication. Credentials are passed via HTTP Basic authentication:

```javascript
// Obtain access token
async function getAccessToken(clientId, clientSecret) {
  // Encode credentials as Base64 for Basic auth
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const response = await fetch(
    'https://auth.bsn.cloud/realms/bsncloud/protocol/openid-connect/token',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${credentials}`,
        'Accept': 'application/json'
      },
      body: new URLSearchParams({
        grant_type: 'client_credentials'
      })
    }
  );

  const data = await response.json();
  // Returns: { access_token, token_type: 'Bearer', expires_in, ... }
  return data.access_token;
}
```

**Important**: The client ID and secret must be sent via HTTP Basic authentication header, not in the request body.

### Device Control

Control devices via API:

```javascript
// Reboot a device
async function rebootDevice(serial, accessToken) {
  // Use Remote DWS WebSocket connection
  const ws = new WebSocket(`wss://dws.bsn.cloud/device/${serial}`);

  ws.onopen = () => {
    ws.send(JSON.stringify({
      method: 'POST',
      path: '/Reboot',
      auth: accessToken
    }));
  };

  ws.onmessage = (event) => {
    const response = JSON.parse(event.data);
    console.log('Reboot initiated:', response);
    ws.close();
  };
}
```

### Webhook Integration

BSN.cloud can send webhooks for events:

- **Device Events**: Online/offline, errors
- **System Events**: Network changes, user actions

Configure webhooks in account settings or via API.

## Advanced Features

### Tagging and Filtering

Organize devices and content with tags:

```javascript
// Add tags to device
async function tagDevice(deviceId, tags, accessToken) {
  const response = await fetch(
    `https://api.bsn.cloud/2020/10/REST/Devices/${deviceId}/Tags/`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(tags)
    }
  );

  return response.status === 204;
}

// Filter devices by tags
const filter = `Tags.Location eq "Store-01" and Tags.Department eq "Electronics"`;
const devices = await listDevices(filter, accessToken);
```

### Device Groups

Create logical device groups:

- **Geographic Groups**: Group by location
- **Functional Groups**: Group by purpose
- **Tagged Groups**: Dynamic groups based on tags
- **Regular Groups**: Static device collections

```javascript
// Create device group
async function createGroup(groupData, accessToken) {
  const response = await fetch(
    'https://api.bsn.cloud/2020/10/REST/Groups/Regular/',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(groupData)
    }
  );

  return await response.json();
}
```

### Role-Based Access

Define granular permissions:

```javascript
// Create custom role
const customRole = {
  name: 'Content Manager',
  permissions: [
    { operation: 'content.create', allow: true },
    { operation: 'content.update', allow: true },
    { operation: 'content.delete', allow: true },
    { operation: 'devices.update', allow: false },
    { operation: 'devices.delete', allow: false }
  ]
};
```

### Custom Plugins

Extend player functionality with plugins:

```javascript
// Upload and assign autorun plugin
async function deployPlugin(pluginFile, deviceIds, accessToken) {
  // 1. Upload plugin
  const formData = new FormData();
  formData.append('file', pluginFile);

  const uploadResponse = await fetch(
    'https://api.bsn.cloud/2020/10/REST/Autoruns/Plugins/',
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${accessToken}` },
      body: formData
    }
  );

  const plugin = await uploadResponse.json();

  // 2. Assign to devices
  for (const deviceId of deviceIds) {
    await fetch(
      `https://api.bsn.cloud/2020/10/REST/Devices/${deviceId}/`,
      {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify([
          {
            op: 'replace',
            path: '/autorunPlugin',
            value: plugin.id
          }
        ])
      }
    );
  }
}
```

### Third-Party Integrations

BSN.cloud integrates with external systems:

- **CMS Integration**: Connect to external content management systems
- **Analytics Platforms**: Export data to Google Analytics, Adobe Analytics
- **Notification Services**: Trigger alerts via Slack, Teams, PagerDuty
- **Data Sources**: Import data from APIs, databases, RSS feeds

## Security & Compliance

### Secure Communications

All BSN.cloud communications are encrypted:

- **TLS 1.2+**: All HTTPS/WebSocket connections
- **Certificate Validation**: Verify server certificates
- **Token-based Auth**: OAuth2 access tokens
- **API Rate Limiting**: Prevent abuse

### Certificate Management

Manage security certificates:

- **Automatic Rotation**: Certificates rotated automatically
- **Custom Certificates**: Upload custom CA certificates if needed
- **Certificate Pinning**: Optional for enhanced security

```javascript
// Upload custom CA certificate (if required)
async function uploadCertificate(certFile, accessToken) {
  const formData = new FormData();
  formData.append('certificate', certFile);

  const response = await fetch(
    'https://api.bsn.cloud/certificates',
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${accessToken}` },
      body: formData
    }
  );

  return await response.json();
}
```

### Access Control

Implement least-privilege access:

- **User Roles**: Assign minimum required permissions
- **API Scopes**: Request only necessary scopes
- **IP Whitelisting**: Restrict API access to known IPs
- **Token Expiration**: Tokens expire after specified duration

### Audit Logging

Track all system activities:

- **User Actions**: Login, content changes, device modifications
- **API Calls**: All API requests logged
- **Device Events**: Device status changes, errors
- **System Events**: Configuration changes

Access audit logs via API or web interface.

### GDPR Compliance

BSN.cloud supports GDPR requirements:

- **Data Minimization**: Collect only necessary data
- **Right to Access**: Users can export their data
- **Right to Deletion**: Data deletion on request
- **Data Retention**: Configurable retention policies
- **Privacy Controls**: Granular privacy settings

## Troubleshooting

### Common Issues

**Player Not Connecting**:
- Verify network connectivity
- Check firewall rules (ports 80, 443, WebSocket)
- Confirm player is registered in BSN.cloud
- Check device activation status

**API Authentication Failures**:
- Verify client credentials
- Check token expiration
- Confirm required scopes
- Review API rate limits

### Network Diagnostics

Required network access:

```
Outbound HTTPS (443):
- api.bsn.cloud
- auth.bsn.cloud
- cdn.bsn.cloud
- dws.bsn.cloud

Outbound WebSocket (443):
- dws.bsn.cloud

Protocols:
- HTTPS/TLS 1.2+
- WebSocket (WSS)
- DNS resolution
```

Test connectivity from player:

```brightscript
' Test BSN.cloud connectivity
function TestBSNConnectivity() as Boolean
  urlTransfer = CreateObject("roUrlTransfer")
  urlTransfer.SetUrl("https://api.bsn.cloud/health")

  response = urlTransfer.GetToString()
  if response <> "" then
    print "BSN.cloud connectivity: OK"
    return true
  else
    print "BSN.cloud connectivity: FAILED"
    return false
  end if
end function
```

### Performance Optimization

Optimize BSN.cloud integration:

**API Optimization**:
- Implement caching for API responses
- Use batch operations when possible
- Paginate large result sets
- Implement retry logic with exponential backoff

**Network Optimization**:
- Schedule large downloads during off-peak hours
- Use content versioning to minimize transfers
- Implement bandwidth throttling
- Monitor network usage

### Support Resources

Get help with BSN.cloud:

- **Documentation**: https://docs.brightsign.biz
- **API Reference**: https://docs.brightsign.biz/display/DOC/BSN.cloud+APIs
- **Support Portal**: https://support.brightsign.biz
- **Community Forum**: https://forums.brightsign.biz
- **Email Support**: support@brightsign.biz
- **Phone Support**: Available for paid tiers

## Required Resources

To work with BSN.cloud integration, you need:

**Accounts and Credentials**:
- BSN.cloud account (free or paid)
- API client credentials (from BrightSign support)
- Network ID (from BSN.cloud dashboard)

**Hardware**:
- BrightSign player(s) with network connectivity
- Network infrastructure (router, internet connection)
- Display(s) connected to players

**Software**:
- Web browser (for BSN.cloud web interface)
- Development tools (for API integration)

**Network Requirements**:
- Outbound internet access (HTTPS, WebSocket)
- Adequate bandwidth for content delivery
- Firewall configuration for BSN.cloud endpoints

## Best Practices

### Network Security Configuration

**Firewall Rules**:
```
# Allow outbound HTTPS
Allow TCP port 443 to api.bsn.cloud
Allow TCP port 443 to auth.bsn.cloud
Allow TCP port 443 to cdn.bsn.cloud
Allow TCP port 443 to dws.bsn.cloud

# Allow DNS
Allow UDP port 53

# Block all other outbound traffic (optional)
```

**Network Segmentation**:
- Isolate digital signage network from corporate network
- Use VLANs to separate traffic
- Implement network monitoring

### Backup and Recovery Strategies

**Configuration Backup**:
- Export device configurations regularly
- Save network settings
- Document custom integrations

**Disaster Recovery**:
- Maintain offline content copies
- Document recovery procedures
- Test recovery process periodically
- Keep emergency contact list

### Monitoring and Alerting Setup

**Health Monitoring**:
```javascript
// Monitor device health
async function monitorDevices(accessToken) {
  const devices = await listAllDevices(accessToken);

  for (const device of devices) {
    const status = await getDeviceStatus(device.id, accessToken);

    // Check critical metrics
    if (status.storageAvailable < 1073741824) { // < 1GB
      sendAlert(`Low storage on ${device.name}`);
    }

    if (Date.now() - status.lastCheckIn > 900000) { // > 15 min
      sendAlert(`Device offline: ${device.name}`);
    }
  }
}

// Run every 5 minutes
setInterval(() => monitorDevices(token), 300000);
```

**Alert Channels**:
- Email notifications
- SMS for critical alerts
- Webhook to monitoring platforms
- Dashboard for real-time status

### Scalability Planning

**Network Growth**:
- Plan for 20-30% annual growth
- Monitor API rate limits
- Consider enterprise tier for large deployments
- Implement efficient querying and filtering

**Performance Considerations**:
- Cache API responses
- Batch operations when possible
- Implement pagination for large datasets
- Use webhooks instead of polling

**Cost Management**:
- Monitor bandwidth usage
- Optimize content sizes
- Review subscription tier regularly
- Archive unused content

## Summary

BSN.cloud provides a comprehensive cloud platform for managing BrightSign digital signage networks. Key capabilities include:

- **Centralized Management**: Control all devices from a single interface
- **Automated Provisioning**: Streamline device deployment with B-Deploy
- **Remote Control**: Manage devices from anywhere via APIs
- **Security**: Enterprise-grade security and compliance
- **Scalability**: Supports networks from single displays to thousands

By leveraging BSN.cloud APIs and following best practices, you can build scalable, secure, and efficient digital signage solutions that meet enterprise requirements.

For the latest API documentation and updates, visit: https://docs.brightsign.biz/display/DOC/BSN.cloud+APIs


---

[↑ Part 5: BSN Cloud](README.md) | [Next →](02-automated-provisioning.md)
