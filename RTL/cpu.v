//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

wire signed [31:0] immediate_extended;

assign immediate_extended = $signed(instruction[15:0]);


pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   .branch_pc (branch_pc ),
   .jump_pc   (jump_pc   ),
   .zero_flag (zero_flag ),
   .branch    (branch    ),
   .jump      (jump      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

control_unit control_unit(
   .opcode   (instruction[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch            ),
   .mem_read (mem_read          ),
   .mem_2_reg(mem_2_reg         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write         ),
   .alu_src  (alu_src           ),
   .reg_write(reg_write         ),
   .jump     (jump              )
);


mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction[15:11]),
   .input_b (instruction[20:16]),
   .select_a(reg_dst          ),
   .mux_out (regfile_waddr     )
);

register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write         ),
   .raddr_1  (instruction[25:21]),
   .raddr_2  (instruction[20:16]),
   .waddr    (regfile_waddr     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);


alu_control alu_ctrl(
   .function_field (instruction[5:0]),
   .alu_op         (alu_op          ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended),
   .input_b (regfile_data_2    ),
   .select_a(alu_src           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out       ),
   .wen      (mem_write     ),
   .ren      (mem_read      ),
   .wdata    (regfile_data_2),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);


mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data    ),
   .input_b  (alu_out      ),
   .select_a (mem_2_reg     ),
   .mux_out  (regfile_wdata)
);


branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc        ),
   .instruction  (instruction       ),
   .branch_offset(immediate_extended),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);

//hardware signals
//IF ID
reg_artsn_en #(.DATA_W(32))
instruction_pipe_IF_ID(
   .clk (clk   ),
   .arst.n(arst_n ),
   .din (instruction ),
   .en (enable )
   .dout (instruction_IF_ID)
);

reg_artsn_en #(.DATA_W(32))
updated_pc_pipe_IF_ID(
   .clk (clk   ),
   .arst.n(arst_n ),
   .din (updated_pc ),
   .en (enable )
   .dout (updated_pc_IF_ID)
);


//ID EX
reg_arstn_en #(.DATA_W(32))
updated_pc_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (updated_pc_IF_ID),
   .en (enable),
   .dout (updated_pc_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
rdata1_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (rdata_1),
   .en (enable),
   .dout (rdata1_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
rdata2_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (rdata_2),
   .en (enable),
   .dout (rdata2_ID_EX)
   );

reg_arstn_en #(.DATA_W(5))
registry_adress_I_type_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (instruction_IF_ID[20:16]),
   .en (enable),
   .dout (adress_I_type_ID_EX)
   );

reg_arstn_en #(.DATA_W(5))
registry_adress_R_type_pipe_ID_eX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (instruction_IF_ID[15:11]),
   .en (enable),
   .dout (adress_R_type_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
immediate_extended_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (instruction_IF_ID[20:16]),
   .en (enable),
   .dout (adress_I_type_ID_EX)
   );

//to branch signal

//EX MEM
reg_arstn_en #(.DATA_W(32))
alu_out_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (alu_out),
   .en (enable),
   .dout (alu_out_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
rdata2_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (rdata2_ID_EX),
   .en (enable),
   .dout (rdata2_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
waddress_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (regfile_waddr),
   .en (enable),
   .dout (waddress_EX_MEM)
   );

//MEM WB
reg_arstn_en #(.DATA_W(32))
waddress_pipe_MEM_WB(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (waddress_EX_MEM),
   .en (enable),
   .dout (waddress_MEM_WB)
   );

reg_arstn_en #(.DATA_W(32))
alu_out_pipe_MEM_WB(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (alu_out_EX_MEM),
   .en (enable),
   .dout (alu_out_MEM_WB)
   );

reg_arstn_en #(.DATA_W(32))
dram_data_pipe_MEM_WB(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (dram_data),
   .en (enable),
   .dout (dram_data_MEM_WB)
   );

//control signals

//ID EX
reg_arstn_en #(.DATA_W(32))
reg_dst_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (reg_dst),
   .en (enable),
   .dout (reg_dst_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
jump_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (jump),
   .en (enable),
   .dout (jump_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
branch_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (branch),
   .en (enable),
   .dout (branch_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
mem_read_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_read),
   .en (enable),
   .dout (mem_read_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
mem_2_reg_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_2_reg),
   .en (enable),
   .dout (mem_2_reg_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
alu_op_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (alu_op),
   .en (enable),
   .dout (alu_op_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
mem_write_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_write),
   .en (enable),
   .dout (mem_write_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
alu_src_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (alu_src),
   .en (enable),
   .dout (alu_src_ID_EX)
   );

reg_arstn_en #(.DATA_W(32))
reg_write_pipe_ID_EX(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (reg_write),
   .en (enable),
   .dout (reg_write_ID_EX)
   );

//EX MEM
reg_arstn_en #(.DATA_W(32))
branch_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (branch_ID_EX),
   .en (enable),
   .dout (branch_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
mem_write_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_write_ID_EX),
   .en (enable),
   .dout (mem_write_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
updated_pc_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (updated_pc_ID_EX),
   .en (enable),
   .dout (updated_pc_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
mem_read_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_read_ID_EX),
   .en (enable),
   .dout (mem_read_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
mem_read_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (mem_read_ID_EX),
   .en (enable),
   .dout (mem_read_EX_MEM)
   );

reg_arstn_en #(.DATA_W(32))
reg_write_pipe_EX_MEM(
   .clk (clk   ),
   .arst.n(arst_n),
   .din (reg_write_ID_EX),
   .en (enable),
   .dout (reg_write_EX_MEM)
   );
endmodule


