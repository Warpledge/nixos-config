#=====================================================================#
# KERNEL SECURITY HARDENING AND OPTIMIZATION
#=====================================================================#
#--- Security tweaks adapted from @hlissner, @linuxmobile
{
  boot = {
    #--------------------------------------------------------------------#
    #-- Kernel Modules
    #--------------------------------------------------------------------#
    kernelModules = [
      "ntsync" # NT synchronization primitives (Wine/Proton NTSync support)
      "v4l2loopback" # Virtual video device driver (OBS support)
      "i2c-dev" # I2C device interface for userspace
      "efivarfs" # EFI variable filesystem
      "tcp_bbr" # BBR congestion control (network performance)
      "nvme_core.default_ps_max_latency_us=0" # NVMe max performance (no power saving)
      "randomize_kstack_offset=on" # Randomize kernel stack (exploit mitigation)
      "vsyscall=none" # Disable legacy syscall interface
      "slab_nomerge" # Disable slab merging (heap attack hardening)
      "lockdown=integrity" # Kernel lockdown mode
      "page_poison=1" # Poison freed memory (use-after-free detection)
      "page_alloc.shuffle=1" # Randomize page allocator
      "sysrq_always_enabled=0" # Disable magic SysRq key
      "rootflags=noatime" # Disable file access time updates
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux" # Enable LSMs
      "fbcon=nodefer" # Show kernel messages immediately
    ];
    #--------------------------------------------------------------------#
    #-- Kernel Sysctls Configuration
    #--------------------------------------------------------------------#
    kernel = {
      sysctl = {
        "kernel.sysrq" = 0; # Disable magic SysRq key
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1; # Ignore bogus ICMP errors
        "net.ipv4.conf.default.rp_filter" = 1; # Reverse path filtering (IP spoofing mitigation)
        "net.ipv4.conf.all.rp_filter" = 1; # Enable on all interfaces
        "net.ipv4.conf.all.accept_source_route" = 0; # Disable source routing
        "net.ipv6.conf.all.accept_source_route" = 0; # Disable IPv6 source routing
        "net.ipv4.conf.all.send_redirects" = 0; # Don't send ICMP redirects
        "net.ipv4.conf.default.send_redirects" = 0; # no redirects
        "net.ipv4.conf.all.accept_redirects" = 0; # Reject ICMP redirects (MITM mitigation)
        "net.ipv4.conf.default.accept_redirects" = 0; # reject redirects
        "net.ipv4.conf.all.secure_redirects" = 0; # Reject secure redirects
        "net.ipv4.conf.default.secure_redirects" = 0; # reject secure redirects
        "net.ipv6.conf.all.accept_redirects" = 0; # Reject IPv6 redirects
        "net.ipv6.conf.default.accept_redirects" = 0; # reject IPv6 redirects
        "net.ipv4.tcp_syncookies" = 1; # SYN flood protection
        "net.ipv4.tcp_rfc1337" = 1; # TIME-WAIT assassination protection
        "net.ipv4.tcp_fastopen" = 3; # TCP Fast Open (both directions)
        "net.ipv4.tcp_congestion_control" = "bbr"; # BBR congestion control
        "net.core.default_qdisc" = "cake"; # CAKE queue discipline (bufferbloat mitigation)
        "net.core.rmem_default" = 262144; # Default RX buffer
        "net.core.rmem_max" = 134217728; # Max RX buffer
        "net.core.wmem_default" = 262144; # Default TX buffer
        "net.core.wmem_max" = 134217728; # Max TX buffer
        "net.ipv4.tcp_rmem" = "4096 131072 134217728"; # TCP RX buffer sizes
        "net.ipv4.tcp_wmem" = "4096 65536 134217728"; # TCP TX buffer sizes
        "net.ipv4.tcp_window_scaling" = 1; # TCP window scaling
        "net.ipv4.tcp_timestamps" = 1; # TCP timestamps
        "net.ipv4.tcp_sack" = 1; # Selective Acknowledgment
        "net.ipv4.tcp_fack" = 1; # Forward Acknowledgment
        "net.ipv4.tcp_low_latency" = 1; # Low latency mode
        "net.ipv4.tcp_adv_win_scale" = 1; # TCP window scale
        "net.ipv4.tcp_fin_timeout" = 15; # Reduce TIME_WAIT sockets
        "net.ipv4.tcp_tw_reuse" = 1; # Reuse TIME_WAIT sockets
        "vm.dirty_ratio" = 10; # Dirty memory threshold (%)
        "vm.dirty_background_ratio" = 5; # Background writeback threshold (%)
        "net.core.netdev_budget" = 600; # NAPI budget
        "net.core.netdev_max_backlog" = 16384; # NIC backlog queue
        "net.ipv4.tcp_no_metrics_save" = 1; # Don't save TCP metrics
        "net.ipv4.tcp_moderate_rcvbuf" = 1; # Moderate RX buffer
        "kernel.kptr_restrict" = 2; # Hide kernel pointers from unprivileged users
        "kernel.ftrace_enabled" = false; # Disable kernel function tracing
        "kernel.dmesg_restrict" = 1; # Restrict dmesg access
        "fs.protected_fifos" = 2; # Protect FIFOs from untrusted writers
        "fs.protected_regular" = 2; # Protect regular files from untrusted writers
        "fs.suid_dumpable" = 0; # Disable core dumps for setuid programs
        "net.core.bpf_jit_harden" = 2; # Harden BPF JIT compiler
        "kernel.core_uses_pid" = 1; # Append PID to core filenames
        "kernel.randomize_va_space" = 2; # Full ASLR
        "vm.mmap_rnd_bits" = 32; # ASLR entropy for mmap
        "vm.mmap_rnd_compat_bits" = 16; # ASLR entropy for compat mmap
        "dev.tty.ldisc_autoload" = 0; # Disable TTY line discipline autoloading
      };
    };

    #--------------------------------------------------------------------#
    #-- Blacklisted Kernel Modules
    #--------------------------------------------------------------------#
    blacklistedKernelModules = [
      "dccp" # Datagram Congestion Control Protocol (rarely used)
      "sctp" # Stream Control Transmission Protocol (rarely used)
      "rds" # Reliable Datagram Sockets (rarely used)
      "tipc" # Transparent Inter-Process Communication (rarely used)
      "n-hdlc" # High-level Data Link Control
      "netrom" # NetRom protocol
      "x25" # X.25 protocol
      "ax25" # Amateur X.25 protocol
      "rose" # ROSE protocol
      "decnet" # DECnet protocol
      "econet" # Econet protocol
      "af_802154" # IEEE 802.15.4 protocol
      "ipx" # Internetwork Packet Exchange
      "appletalk" # AppleTalk protocol
      "psnap" # Subnetwork Access Protocol
      "p8022" # IEEE 802.3 protocol
      "p8023" # Novell raw IEEE 802.3
      "can" # Controller Area Network
      "atm" # ATM protocol
      "adfs" # Acorn Disc Filing System
      "affs" # Amiga Fast File System
      "befs" # Be File System
      "bfs" # SCO Unix FS
      "cramfs" # Compressed ROM/RAM filesystem
      "efs" # Extent File System
      "erofs" # Enhanced Read-Only File System
      "exofs" # Extended Object File System
      "freevxfs" # Veritas filesystem driver
      "f2fs" # Flash-Friendly File System
      "vivid" # Virtual video test driver (security risk)
      "gfs2" # Global File System 2
      "hpfs" # High Performance File System (OS/2)
      "hfs" # Hierarchical File System (Macintosh)
      "hfsplus" # HFS+ with extended attributes
      "jffs2" # Journalling Flash File System (v2)
      "jfs" # Journaled File System
      "ksmbd" # SMB3 Kernel Server
      "minix" # Minix FS
      "nfsv3" # Network File System (v3)
      "nfsv4" # Network File System (v4)
      "nfs" # Network File System
      "nilfs2" # Log-structured File System
      "omfs" # Optimized MPEG Filesystem
      "qnx4" # QNX4/QNX6 filesystem
      "qnx6" # QNX6 filesystem
      "sysv" # System V filesystem variants
      "udf" # Universal Disk Format
      "firewire-core" # Prevent DMA attacks via FireWire
      "thunderbolt" # Prevent DMA attacks via Thunderbolt
      "esp4" # CVE-2026-46300: LPE via XFRM ESP-in-TCP (no IPsec in use)
      "esp6" # CVE-2026-46300: LPE via XFRM ESP-in-TCP (no IPsec in use)
      "rxrpc" # CVE-2026-46300: LPE via XFRM ESP-in-TCP / kAFS dep (not used)
    ];

    #--------------------------------------------------------------------#
    #-- Modprobe Configuration
    #--------------------------------------------------------------------#
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Output"
      options rtw88_core disable_lps_deep=y
      options rtw88_pci disable_aspm=y
    '';
  };
}
