//////////////////////////////////////////////////////////////////////////////////
// Company: Embedded Computing Lab, Korea University
// Engineer: Kwon Guyun - 1216kg@naver.com
// 			 Fennira Alaeddine - alaeddine.fennira@etu.sorbonne-universite.fr
// Create Date: 2021/07/01 11:04:31
// Design Name: ov7670_core
// Module Name: ov7670_core
// Project Name: project_ov7670
// Target Devices: zedboard
// Tool Versions: Vivado 2019.1
// Description: get a image like data and process it before send it to vga and lenet
//              
// Dependencies: 
// 
// Revision 1.00 - first well-activate version
// Additional Comments: reference design: http://www.nazim.ru/2512
//                                        can change center image to lower resolution
// 
//////////////////////////////////////////////////////////////////////////////////
module core #(
            parameter width = 640,
            parameter height = 480,
			parameter hMaxCount = 640 + 16 + 96 + 48,
			parameter vMaxCount = 480 + 10 + 2 + 33,
            
            localparam c_frame = hMaxCount * vMaxCount - 1
            )
            (
			input                         clk24,
			input        [7:0]	          din,
			input                         rst_n,
			
			output       [18:0]	          addr_mem0,
			output       [18:0]	          addr_mem1,
			output logic [3:0]	          dout,
			output logic                  we,
			
			output logic                  core_end
			);
	
	
	logic[18:0]	   counter;
	logic[10:0]    hor, ver;
	logic[18:0]	   address_mem0;
	logic[18:0]    address_mem1;
    logic we_t;
    
    logic          go;
    logic          step;
    logic [3:0]	   gx;
	logic [3:0]	   gy;
	//real          g;
    logic [8:0]   gxr;
	
    assign addr_mem0 = address_mem0;
    assign addr_mem1 = address_mem1;
    assign core_end = counter == c_frame;

//declaration and initialization of Sobel masks
    int arrayX[8:0];
    int arrayY[8:0];
    logic[3:0] arrayPixels[8:0];
    logic[3:0] arrayCounter; //counter for arrayPixels
  
    initial begin
        arrayX  = '{-1,-2,-1,0,0,0,1,2,1};
        arrayY  = '{-1,0,1,-2,0,2,-1,0,1};
        arrayPixels  <= '{0,0,0,0,0,0,0,0,0};
        arrayCounter <= '0;
        go <= '0;
        step <= '1; 
    end

// counter - count per pixel - used for checking one frame processing ends.
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_counter                                        
        if(~rst_n) begin
            counter <= '0;
        end 
        else begin
            if (core_end) begin
                counter <= '0;
            end 
            else begin
                if (step == 1) begin
                    counter <= counter + 1;
                end
            end
        end
    end

//step - Controlling incrementation of hor and ver and counter
always_ff @(posedge clk24 or negedge rst_n) begin : proc_step                                  
        if(~rst_n) begin
            step  <= '1;
        end 
        else begin
            if ((hor == 0) && (hor <= width - 1) && (ver == 0) && (ver <= height - 1)) begin
                step <= '1;
            end
            else begin
                if (arrayCounter <= 4'b1000) begin
                    step <= '0;
                end
                else begin
                    step <= '1;
                end
            end
        end
end 

// address_mem0 - address of pixel of input data
// address for ouput image's pixel - this will be shown on the monitor
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_address_mem0                                   
        if(~rst_n) begin
            address_mem0 <= 0;
        end 
        else begin
            if ((hor != 0) && (hor != width - 1) && (ver != 0) && (ver != height - 1)) begin
                case (arrayCounter)
                    4'b0000:          address_mem0 = (ver - 1) * width + hor - 1; 
                    4'b0001:          address_mem0 = (ver - 1) * width + hor;
                    4'b0010:          address_mem0 = (ver - 1) * width + hor + 1;
                    4'b0011:          address_mem0 = ver * width + hor - 1;
                    4'b0100:          address_mem0 = ver * width + hor;
                    4'b0101:          address_mem0 = ver * width + hor + 1;
                    4'b0110:          address_mem0 = (ver + 1) * width + hor - 1;
                    4'b0111:          address_mem0 = (ver + 1) * width + hor;
                    4'b1000:          address_mem0 = (ver + 1) * width + hor + 1; 
                    default:          address_mem0 = ver * width + hor;                                 
                endcase
            end
            else begin
                address_mem0 <= ver * width + hor;
            end
   end
end 
        
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_hor_ver                                   
        if(~rst_n) begin
            hor <= 0;
            ver <= 0;
            step <= 1;
        end 
        else begin
            if (core_end) begin
                hor <= 0;
                ver <= 0;
            end 
            else begin
                if (step == 1) begin 
                    if (hor == hMaxCount - 1) begin
                        hor <= 0;
                        ver <= ver + 1;
                    end 
                    else begin
                        hor <= hor + 1;
                    end
                end
            end
        end
    end  
      
// reading 3*3 pixels array before filtering them.
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_pixels_array                                        
        if(~rst_n) begin
            arrayPixels  <= '{0,0,0,0,0,0,0,0,0};
            arrayCounter <= 4'b0000;
            go <= '0;
        end 
        else begin
            if (core_end) begin
                arrayCounter <= 4'b0000;
                go <= '0;
            end 
            else begin
                if ((hor != 0) && (hor != width - 1) && (ver != 0) && (ver != height - 1)) begin
                    arrayPixels[arrayCounter] = din[7:4];
                    if (arrayCounter <= 4'b1000) begin
                        arrayCounter++;
                        go <= '0;
                    end
                    else begin
                        arrayCounter <= 4'b0000;
                        go <= '1;
                    end
                end
            end
        end
    end
    
// address for ouput image's pixel - this will be shown on the monitor
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_address_mem1                                   
        if(~rst_n) begin
            address_mem1 <= 0;
        end 
        else begin
            address_mem1 <=  ver * width + hor;
        end
    end
 
 // Sobel mask for x-direction and y-direction
always_ff @(posedge clk24 or negedge rst_n) begin : proc_g                                            
        if(~rst_n) begin
            gx <= '0;
            gy <= '0;
        end 
/*        else begin
            if (core_end) begin //unnecessary ? 
                gx = '0;
                gy = '0;
            end */
            else begin 
                gx <= '0;
                gy <= '0;
                if (go == 1) begin
                    for (int i = 0 ; i < 9 ; i++) begin
                        //gx <= gx + arrayPixels[i] * arrayX[0][i] + arrayPixels[i+6] * arrayX[2][i];
                        //gy <= gy + arrayPixels[i] * arrayY[0][i] + arrayPixels[2][i] * arrayY[2][i];
                        gx <= gx + arrayPixels[i] * arrayX[i];
                        gy <= gy + arrayPixels[i] * arrayY[i];
                    end
                    //go_vga <= 1;
                end
            end
        end

// vga output pixel data
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_dout                                            
        if(~rst_n) begin
            dout <= '0;
        end 
        else begin
            //if (core_end | (hor == 0) | (hor == width - 1) | (ver == 0) | (ver == height - 1)) begin
            /*if ((hor == 0) || (hor >= width - 1) || (ver == 0) || (ver >= height - 1)) begin
                dout <= '0;
            end */
            if (core_end) begin
                dout <= '0;
            end 
            else begin
                gxr = (gx * gx) + (gy * gy);
				/* The squareroot instruction is not synthesisable*/
				/* => Affect the result manually */
                /*gyr <= 
                g = $bitstoreal(gxr);
                gl = $sqrt(g);
                dout <= $realtobits(gl);*/
                //if (go_vga == 1) begin
                /* square root of gradient gxr*/
                case (gxr) inside
                //Round to bigger integer + (Threshold 0.70) + (magnitude *2)
                    [9'b000000000:9'b100111010]:          dout = 4'b0000;
                    [9'b100111011:9'b111000010]:          dout = gxr[8:5]*2;
                    default:          dout = 4'b1111;  
                    /*0:              dout =  0;
                    1 , 2 :         dout =  1;
                    [3:6]:          dout =  2;
                    [7:12]:         dout =  3;
                    [8:20]:         dout =  4;
                    [21:30]:        dout =  5;
                    [31:42]:        dout =  6;
                    [43:56]:        dout =  7;
                    [57:72]:        dout =  8;
                    [73:90]:        dout =  9;
                    [91:110]:       dout = 10;
                    [111:132]:      dout = 11;
                    [133:156]:      dout = 12;
                    [157:182]:      dout = 13;
                    [183:210]:      dout = 14;
                    [210:450]:      dout = 15;*/
                    //Round to bigger integer if > x.5 (example: 3.4 is rounded to 3 and 3.6 is rounded to 4)
                    /*4'b0000:          dout = 4'b0000;
                    4'b0001:          dout = 4'b0001;
                    4'b0010:          dout = 4'b0001;
                    4'b0011:          dout = 4'b0010;
                    4'b0100:          dout = 4'b0010;
                    4'b0101:          dout = 4'b0010;
                    4'b0110:          dout = 4'b0010;
                    4'b0111:          dout = 4'b0011;
                    4'b1000:          dout = 4'b0011;
                    4'b1001:          dout = 4'b0011;
                    4'b1010:          dout = 4'b0011;
                    4'b1011:          dout = 4'b0011;
                    4'b1100:          dout = 4'b0011;
                    4'b1101:          dout = 4'b0100;
                    4'b1110:          dout = 4'b0100;
                    4'b1111:          dout = 4'b0100;
                    default:          dout = 4'b1111;*/
                    //Round always to bigger integer (example: 3.4 and 3.6 are rounded to 4)
                    /*4'b0000:          dout = 4'b0000;
                    4'b0001:          dout = 4'b0010;
                    4'b0010:          dout = 4'b0010;
                    4'b0011:          dout = 4'b0011;
                    4'b0100:          dout = 4'b0011;
                    4'b0101:          dout = 4'b0011;
                    4'b0110:          dout = 4'b0011;
                    4'b0111:          dout = 4'b0100;
                    4'b1000:          dout = 4'b0100;
                    4'b1001:          dout = 4'b0100;
                    4'b1010:          dout = 4'b0100;
                    4'b1011:          dout = 4'b0100;
                    4'b1100:          dout = 4'b0100;
                    4'b1101:          dout = 4'b0101;
                    4'b1110:          dout = 4'b0101;
                    4'b1111:          dout = 4'b0101;
                    default:          dout = 4'b1111;  */
                endcase
            end
        end
  end

// write enable of vga output pixel
    always_ff @(posedge clk24 or negedge rst_n) begin : proc_we                                             
        if(~rst_n) begin
            we <= 0;
            we_t <= 0;
        end 
        else begin
            we <= we_t;
            if (hor < width && ver < height) begin
                we_t <= 1'b1;
            end 
            else begin
                we_t <= 1'b0;
            end
        end
    end

    
endmodule // core
