# Experimental extension direction

No third-party WASM executor is shipped. Compiling MoonBit to WASM is different
from hosting guest modules. Before implementing the extension, validate a host
with memory/fuel/deadline limits, cancellation, trap handling and ABI validation.
The intended ABI is bounded JSON input/output, with each Kubernetes action
authorized by the host; no credentials, filesystem or network in the guest.
A callback wrapper is not a sandbox and is not advertised as one here.
