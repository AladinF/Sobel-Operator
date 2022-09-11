# Sobel-Operator
Applying a Sobel operator to a black and white OV7670 output

This project is based on the ov7670_to_vga project (accessible here: https://github.com/ESCA-RISC-V/ov7670_to_vga)

The Sobel operator is 2-D spatial gradient operation on an image to detect and enhance the edges. 
It consists of a pair of 3×3 kernels which are convolved with the original image to calculate approximations of the derivatives 
These kernels are designed to respond maximally to edges running vertically (Gy) and horizontally (Gx) relative to the pixel grid (A), with one kernel for each perpendicular orientation. 
![image](https://user-images.githubusercontent.com/58849076/189539995-444f0854-56e8-4d15-8c5d-eb3b5664aa80.png)

The magnitude of the gradient (G) can be calculated to show the image result after applying the Sobel operator.
![image](https://user-images.githubusercontent.com/58849076/189540011-34a0c849-85f2-440a-bfd7-4fc835dfafb1.png)

The kernels can be applied separately to surface measurement, to produce separate calculations of the gradient component in each orientation. 
In this project, Sobel operator is used for edge detection. A threshold is defined for optimal enhancement (if the value is superior to 0.7, it's a black pixel, 


