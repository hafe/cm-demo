# cm-demo
Simple demo of cert-manager using a kind cluster

Controlled by a makefile is the deployment that includes:

* A two node kind cluster
* cert-manager deployed using helm
* A cluster CA (issuer)
* A simple nginx app with a certificate mounted as a secret

# Use cases

## Install required tools

```
make install
```

Or to force install (upgrade) tools:
```
make force-install
```

## Deploy everything

```
make
```

## Renew certificate

```
make cert-renew
```

## Clean up

Below command is just a shorthand to delete the kind cluster:

```
make clean
```
