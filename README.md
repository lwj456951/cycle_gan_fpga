<!--
 * @Author: jia200151@126.com
 * @Date: 2025-10-30 12:23:29
 * @LastEditors: lwj
 * @LastEditTime: 2026-01-06 20:05:35
 * @FilePath: \undefinedd:\Voice_Conversion_Project\NPU\cycle_gan_fpga\README.md
 * @Description: 
 * Copyright (c) 2025 by lwj email: jia200151@126.com, All Rights Reserved.
-->
# cycle_gan_fpga
2025/11/01
 计算核心PE conv1d.v，乘加树结构参考booth算法和wallace树 一维序列卷积架构：一维脉动阵列，脉动阵列详见《AI处理器硬件架构设计》

 2025/11/11
 完成带有分块矩阵累加的矩阵乘法器的rtl编写。
 开始debug。
 2026/01/06
 vector register core testbench