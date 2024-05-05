# The WOZ Operating System

The Goal of this project is to get a working operating system up and running

## What can it do right now

- Boot Up on risc V
- Print Hello world on Serial Console

## What is 'Working' defined as

The following things are the bare minimum

- Booting Up on RiscV
- Using VGA
- Able to use the Multi Core CPU, RAM, Display, Keyboard
- Memory management
- Multiprocess support
- Running executables
- Atleast SATA support
- File system access
- Providing Modules Support
- Mouse Support
- Booting Up on x86_64

The following is are the Goals after acheiving the above

- Networking
- Sound
- Supporting Full USB, PCIE, etc.
- Supporting Cryptographic extensions
- Providing a Proper userspace

The following are the dreams of the deranged, but i am hopeful that they will come true

- Providing drivers for GPUs with support for atleast Vulkan
- Providing Power Management Support
- Providing Virtualization support
- Providing a GUI interface
- Booting up on other architectures

## Is this going to be compatible with some other os?

The goal is to make the core of the OS flexible enough that we can support linux and windows via modules, but the core should be able to provide every service the other two provide

NOTE: This is the on the bottom of the pririty stack, and there is not going to be any support regarding this by me
