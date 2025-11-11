/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-11-05 10:16:16
 * @LastEditors: lwj
 * @LastEditTime: 2025-11-05 10:16:16
 * @FilePath: \rtl\conv2d\CSA_3_2.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
/*** 
 * @Author: jia200151@126.com
 * @Date: 2025-10-29 15:58:57
 * @LastEditors: lwj
 * @LastEditTime: 2025-10-29 17:24:53
 * @FilePath: \conv1d\CSA_3_2.v
 * @Description: 
 * @Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
 */
module CSA_3_2 (
    input a,
    input b,
    input cin,
    output cout,
    output sum
);//3:2 CSA == full adder
assign sum = a^b^cin;
assign cout = (a&&b)||(cin&&(a||b));
endmodule