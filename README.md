<table border="0">
  <tr>
    <td align="left" valign="middle">
    <h1>Hardware Design Examples</h1>
  </td>
  <td align="left" valign="middle">
    <a href="https://www.silabs.com/wireless">
      <img src="http://pages.silabs.com/rs/634-SLU-379/images/WGX-transparent.png"  title="Wireless and RF Solutions" alt="Wireless and RF Solutions" width="250"/>
    </a>
  </td>
  </tr>
</table>

# Silicon Labs Hardware Design Examples #

This repository contains hardware design examples using Silicon Labs' devices. The main purpose of these examples is to accelerate the initial development process by providing a ready-to-use hardware platform.

Besides the design files, typically a test report and/or a user's manual is included summarizing some performance details of a built test unit sample.

## How to use the examples ##
The designs include complete manufacturing data files that can be used to fabricate the PCBs and pupolate them with the required components. After these steps the assembled units can be used to start the software/firmware development.

The designs can be also used as a starting point for further hardware development and modified freely according to the specific requirements.

## Organization of the Hardware Design Examples (Branches and Folders) ##
The examples are organized into branches of this repository based on the used device family. The designs belonging to the same device family can be found in the branch named accordingly.

Under the branches the folder naming convention is the following:

DeviceFamily_PackageType_Frequency_TXPower_NumberOfLayers_OtherInformation\


## Examples ##

The repository contains the following Hardware Design Examples:
- EFR32xG1x_QFN48_434MHz_10dBm_4layers_IPD
- EFR32xG1x_QFN48_868MHz_13dBm_4layers_IPD
- EFR32xG1x_QFN48_subGHz_14/20dBm_4layers_Discrete_SingleBand
- EFR32xG1x_QFN48_subGHz_19.5dBm_4layers_Discrete_MultiBand
- EFR32xG1x_QFN48_subGHz_19dBm_4layers_Discrete_WideBand
- EFR32xG1x_QFN48_subGHz_20dBm_4layers_Discrete_DualBand
- EFR32xG1x_QFN48_subGHz_20dBm_4layers_Discrete_Dual-WideBand
- EFR32xG22_QFN32_2p4GHz_6dBm_2layers_Low_Cost
- EFR32xG22_QFN32_2p4GHz_6dBm_4layers_BLE_Tag
- EFR32xG24_QFN40_2p4GHz_0dBm_4layers_MinimumBOM

# Antenna Simulation Workbench

This repository also includes an Antenna Simulation Workbench written for OpenEMS, that is designed to help with PCB antenna design and tuning. A guide for getting started and multiple useful examples can be found in the appropriate branch.

# Disclaimer / Terms and Conditions ##

The Hardware Design Examples and the Antenna Simulation Workbench in this repository are provided AS IS. By downloading and using them, the user assumes and bears all liability emerging from the application of these examples.