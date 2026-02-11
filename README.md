This is a personal build of universalblue fedora silverblue, with niri as a main DE and gnome as fallback (may get rid of it later) 

It runs well on the FriendlyElec NanopPC T6 LTS with UEFI (https://github.com/edk2-porting/edk2-rk3588)

Not intended for public use as I'll likely break your workflow to suit mine now and then but you can take inspiration and build your own:

Follow https://blue-build.org/ doc to create the repo, upload your recipe.yaml and switch the action runner to a local arm64 machine you own

# niri-arch64-uefi &nbsp; [![bluebuild build badge](https://github.com/citral23/niri-arch64-uefi/actions/workflows/build.yml/badge.svg)](https://github.com/citral23/niri-arch64-uefi/actions/workflows/build.yml)

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for quick setup instructions for setting up your own repository based on this template.

After setup, it is recommended you update this README to describe your custom image.

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/citral23/niri-arch64-uefi:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/citral23/niri-arch64-uefi:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/citral23/niri-arch64-uefi
```
