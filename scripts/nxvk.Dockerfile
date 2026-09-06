FROM nxvk

# Meson generates a few host-side Rust commands that invoke `rustc` directly.
# NXVK's base image installs Rust under /opt/rust/cargo/bin, which is not kept
# in Ninja's sanitized command environment.
RUN ln -sf /opt/rust/cargo/bin/rustc /usr/local/bin/rustc
