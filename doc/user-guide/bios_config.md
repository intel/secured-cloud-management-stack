# Config BIOS

## Enable TME

```text
Socket Configuration -> Processor Configuration -> TME, MK-TME, TDX -> Total Memory Encryption -> Enabled
```

*NOTE: SGX will be visible only if TME is enabled.*

## Disable UMA-Based Clustering (Otherwise SGX will be grayed out)

```text
Socket Configuration -> Common RefCode Configuration -> UMA-Based Clustering -> Disable
```

## Enable SGX

```text
Socket Configuration -> Processor Configuration -> SW Guard Extensions(SGX) -> Enabled
Socket Configuration -> Processor Configuration -> SGX Package Info In-Band Access --> Enable
Socket Configuration -> Processor Configuration -> Enable/Disable SGX Auto MP Registration Agent --> Enable
```

## Disable Patrol scrub (Only LCC & HCC):

```text
Socket Configuration -> Memory Configuration -> Memory RAS Configuration -> Patrol Scrub -> Disabled
```

## Disable Mirroring:

```text
Socket Configuration -> Memory Configuration -> Memory RAS Configuration -> Mirror Mode -> Disabled
```
