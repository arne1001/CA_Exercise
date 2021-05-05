


module forwarding_unit(
   	input wire [      4:0] register_rd_EXMEM,
		input wire [      4:0] register_rd_MEMWB,
      input wire [      4:0] register_addr1,
      input wire [      4:0] register_addr2,
      input wire             registrywrite_EXMEM,
      input wire             registrywrite_MEMWB,
		output reg             forwardA,
      output reg             forwardB
   );
   
   always@(*)begin
      if((registrywrite_EXMEM == 1'b1) && (register_rd_EXMEM == register_addr1))begin
         forwardA = 1'b1;
      end else begin
         forwardA = 1'b0;
      end
         
      if((registrywrite_EXMEM == 1'b1) && (register_rd_EXMEM == register_addr2))begin
         forwardB = 1'b1;
      end else begin
         forwardB = 1'b0;
      end

      if((registrywrite_MEMWB == 1'b1) && (register_rd_MEMWB == register_addr1))begin
         forwardA = 1'b1;
      end else begin
         forwardB = 1'b0;
      end
         
      if((registrywrite_MEMWB == 1'b1) && (register_rd_MEMWB == register_addr2))begin
         forwardB = 1'b1;
      end else begin
         forwardB = 1'b0;
      end

   end

endmodule



