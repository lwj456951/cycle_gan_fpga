/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-05 10:16:28
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-05 10:16:31
 * @FilePath: \rtl\conv2d\Booth_Encoder.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-30 17:10:38
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-31 16:39:29
 * @FilePath: \conv1d\Booth_Encoder.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
/***
 * @Author: jia200151@126.com
 * @Date: 2025-10-30 17:10:38
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-30 19:12:51
 * @FilePath: \conv1d\Booth_Encoder.v
 * @Description:
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
`timescale 1ns/1ps
`include"./define.v"
module Booth_Encoder (input[`WIDTH_DATA-1:0] weight,
                      input[`WIDTH_DATA-1:0] feature,
                      output reg [`WIDTH_DATA*2*8-1:0] PP);
    integer i;
    wire[`WIDTH_DATA:0] PP_0;
    assign PP_0 = {weight,1'b0};//a_-1 = 0;
    //Partial Product Coeffience
    reg  signed  [2:0]  PPC[0:`WIDTH_DATA/2-1];
    always @(*) begin
        for(i = 0;i<`WIDTH_DATA/2;i = i+1)begin
            $display("PP:%b",PP_0[i+:3]);
            case(PP_0[2*i+:3])//(i+2 i+1 i)
                3'd0:PPC[i] <= 3'd0;
                3'd1:PPC[i] <= 3'd1;
                3'd2:PPC[i] <= 3'd1;
                3'd3:PPC[i] <= 3'd2;
                3'd4:PPC[i] <= -3'sd2;
                3'd5:PPC[i] <= -3'sd1;
                3'd6:PPC[i] <= -3'sd1;
                3'd7:PPC[i] <= 3'd0;
            endcase
            
        end
    end
    //Partial Product
    
    always @(*) begin
        for(i = 0;i<`WIDTH_DATA/2;i = i+1)begin
            case(PPC[i])//(i+2 i+1 i)
                3'd0:PP[i*`WIDTH_DATA*2+:`WIDTH_DATA*2]   <= `WIDTH_DATA*2'd0;//0
                3'd1:PP[i*`WIDTH_DATA*2+:`WIDTH_DATA*2]   <= {{`WIDTH_DATA{feature[`WIDTH_DATA-1]}},feature}<<2*i;//weight
                3'd2:PP[i*`WIDTH_DATA*2+:`WIDTH_DATA*2]   <= {{`WIDTH_DATA{feature[`WIDTH_DATA-1]}},feature}<<(2*i+1);//weight*2
                -3'sd1:PP[i*`WIDTH_DATA*2+:`WIDTH_DATA*2] <= (~{{`WIDTH_DATA{feature[`WIDTH_DATA-1]}},feature}+1)<<2*i;//weight*-1
                -3'sd2:PP[i*`WIDTH_DATA*2+:`WIDTH_DATA*2] <= (~{{`WIDTH_DATA{feature[`WIDTH_DATA-1]}},feature}+1)<<(2*i+1);//weight*-2
            endcase
            
        end
    end
endmodule
