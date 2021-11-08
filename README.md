# cm-demo
Simple demo of cert-manager using a kind cluster

Controlled by a makefile

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
