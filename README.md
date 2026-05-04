# FPGA I2C Driver & Odometry Interface

## Project Overview

This repository contains a comprehensive, Verilog-based **I2C Master Controller** architecture tailored for FPGA systems. Moving beyond a simple communication protocol, this project provides a complete, hardware-level subsystem for interfacing with I2C peripherals, specifically targeting encoder and odometry data collection for motion control or robotics applications.

## Architecture & Implemented Techniques

This project emphasizes robust hardware design, modularity, and rigorous simulation-based verification:

*   **Modular Abstraction**: The system cleanly separates the physical I2C transaction layer (`i2c_master.v`) from the application-level logic. Higher-level modules like the `control_unit.v`, `encoder_interface.v`, and `odom_interface.v` handle the specific state machines required to request and parse sensor data without needing to manage the raw SDA/SCL lines.
*   **Odometry Integration**: Features dedicated logic (`odom_interface.v`) designed to stream and manage positional tracking data, converting high-level system requests into standard I2C read/write sequences.
*   **Extensive Verification Suite**: Employs a robust Test-Driven Development (TDD) approach for hardware. The repository includes granular testbenches for isolated operations:
    *   Component testing (`TB_control_unit.v`, `TB_encoder_interface.v`).
    *   Protocol-level read/write validation (`TB_i2c_master_READ.v`, `TB_i2c_master_WRITE.v`).
    *   A unified system integration test (`TB_Everything.v`).
*   **Mock Peripheral Simulation**: Utilizes a simulated I2C slave device (`testing_I2C_Device.v`) to validate master-slave handshake interactions and clock stretching purely in software simulation, allowing for rapid testing without physical hardware.
*   **Build Automation**: Integrates a `Makefile` to streamline the compilation and simulation workflows, bypassing the need to exclusively rely on GUI-based compilation. 
*   **Hardware Mapping**: Includes explicit physical pin constraints (`pinmap.pcf`, `c5_pin_model_dump.txt`) alongside standard Quartus project files, ensuring the design is ready for target synthesis.
