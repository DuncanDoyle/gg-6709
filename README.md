# Gloo-6709 Reproducer

Issue: https://github.com/solo-io/solo-projects/issues/6709

## Installation

Add Gloo EE Helm repo:
```
helm repo add glooe https://storage.googleapis.com/gloo-ee-helm
```

Export your Gloo Gateway License Key to an environment variable:
```
export GLOO_GATEWAY_LICENSE_KEY={your license key}
```

Install Gloo Gateway:
```
cd install
./install-gloo-gateway-with-helm.sh
```

> NOTE
> The Gloo Gateway version that will be installed is set in a variable at the top of the `install/install-gloo-gateway-with-helm.sh` installation script.

## Setup the environment

Run the `install/setup.sh` script to setup the environment:

- Deploy the HTTPBin application
- Deploy the VirtualServices
- Deploy the K8S Gateway API ingress-gw
- Deploy the ReferenceGrants
- Deploy the HTTPRoute

```
./setup.sh
```

## Call HTTPBin

The HTTPBin service can now be accessed via the "classic" Gloo Edge `gateway-proxy` proxy on port 80 and the new K8S Gateway API `ingress-gw` proxy on port 81.

```
curl -v http://api.example.com/get
```

```
curl -v http://api.example.com/get
```

Let's test the caching. We've enabled caching in the Helm values, but have not configured anything in our HttpListenerOptions.

Gloo Edge"
```
curl -sSD - -o /dev/null http://api.example.com/cache/30
```

K8S Gateway API
```
curl -sSD - -o /dev/null http://api.example.com:81/cache/30
```

The 30 in the path is the value in seconds that we're asking httpbin to set on the cache-control response header's max-age directive. Now send a new request within 30 seconds to the same endpoint.

Gloo Edge:
```
curl -sSD - -o /dev/null http://api.example.com/cache/30
```

K8S Gateway API:
```
curl -sSD - -o /dev/null http://api.example.com:81/cache/30
```

The second request will include a new age header in its response and the timestamp in the date header will be the same as the response from the first request. This means caching has been applied, even though we did not opt in to caching with a HttpListenerOption resource.

This behaviour applies both to the classic API and the K8S Gateway API.

## Disable caching

Although our documentation says that you need to "opt-in" to enable caching on the HTTPListener, what happens if we enable caching in our Helm values is that the following configuration is set in the Gloo Settings:

```
spec:
  cachingServer:
    cachingServiceRef:
      name: caching-service
      namespace: gloo-system
```

... and this seems to enable caching on all http listeners, regardless of the http listener options set.

To disable caching, remove the `cachingServer` configuration from the Gloo Settings:

```
kubectl apply -f settings/settings.yaml
```

Next, repeat the cURL requests used earlier to verify that the timestamp in the date header now changes, showing that caching is disabled:

Gloo Edge:
```
curl -sSD - -o /dev/null http://api.example.com/cache/30
```

K8S Gateway API:
```
curl -sSD - -o /dev/null http://api.example.com:81/cache/30
```

We can now enable the cache on the Gloo Edge gateway-proxy by configuring the `Gateway` CRs `httpGateway/options`:
```
kubectl apply -f gateways/gateway-proxy-with-caching.yaml
```

Observe that caching is enabled again:
```
curl -sSD - -o /dev/null http://api.example.com/cache/30
```

We can do the same with the K8S Gateway API by deploying an `HttpListenerOption` and targeting the correct listener section in our K8S Gateway API `Gateway` CR:
```
kubectl apply -f policies/http-listener-option.yaml
```

Observe that caching is enabled again:
```
curl -sSD - -o /dev/null http://api.example.com:81/cache/30
```

## Conclusion
By enabling the Caching extension in the Gloo Gateway Helm values, the Gloo `Settings` CR is configured with the following section:

```
spec:
  cachingServer:
    cachingServiceRef:
      name: caching-service
      namespace: gloo-system
```

This enables caching on ALL http listeners. To allow the user to selectively configure caching, remove the given configuration from the `Settings` CR and configure caching using the HttpListenerOptions.