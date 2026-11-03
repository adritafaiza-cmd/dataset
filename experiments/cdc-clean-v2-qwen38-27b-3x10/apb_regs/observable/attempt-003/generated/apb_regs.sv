module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd0,
  parameter int unsigned        ApbAddrWidth = 32'd0,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd0,
  parameter int unsigned        RegDataWidth = 32'd0,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type apb_addr_t                  = logic[ApbAddrWidth-1:0],
  parameter type reg_data_t                  = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Extract APB signals from req_t
  wire        psel    = req_i.psel;
  wire        penable = req_i.penable;
  wire        pwrite  = req_i.pwrite;
  wire [ApbAddrWidth-1:0] paddr = req_i.paddr;
  wire [ApbDataWidth-1:0] pwdata = req_i.pwdata;
  wire [ApbDataWidth/8-1:0] pstrb = req_i.pstrb;

  // Response
  assign resp_o.pready = 1'b1;
  assign resp_o.pslverr = 1'b0;
  assign resp_o.prdata = 8'h0; // Not used in this simplified interface

  // Address decoding
  wire [ApbAddrWidth-1:0] offset_addr = paddr - base_addr_i;
  wire [ApbAddrWidth-1:0] reg_index_raw = offset_addr / AddrOffset;
  wire [ApbAddrWidth-1:0] reg_index = (reg_index_raw < NoApbRegs) ? reg_index_raw : NoApbRegs;
  wire valid_addr = (reg_index_raw < NoApbRegs);

  // Write enable: only during APB access (psel & penable) and valid address
  wire write_en = psel & penable & pwrite & valid_addr;

  // Byte strobe mapping: map APB data width bytes to register data width bytes
  // RegDataWidth may be smaller than ApbDataWidth
  localparam int unsigned ApbBytes = ApbDataWidth / 8;
  localparam int unsigned RegBytes = RegDataWidth / 8;

  // For each register, compute the new value based on byte strobes
  // We need to handle the case where RegDataWidth < ApbDataWidth
  // Only the lower RegBytes bytes of pwdata are relevant

  // Generate byte-level write enables for each register
  // For register i, if write_en and i == reg_index, apply strobes
  // The strobes pstrb[j] correspond to byte j of pwdata
  // For register data, byte j (0-indexed from LSB) is updated if pstrb[j] is set
  // and j < RegBytes

  // We'll build the new register value for the addressed register
  // For other registers, keep current value

  // Helper: for a given register index, compute the updated value
  // We use a combinational block to compute the next value for the addressed register

  // Since we can't easily do variable-index writes in a simple way,
  // we'll use a case statement or generate block

  // Let's use a generate block to create the next-state logic for each register

  // For each register i:
  //   if (write_en && (reg_index == i) && !ReadOnly[i])
  //     for each byte j in 0..RegBytes-1:
  //       if (pstrb[j])
  //         next_reg[i][j*8 +: 8] = pwdata[j*8 +: 8]
  //       else
  //         next_reg[i][j*8 +: 8] = reg_q_o[i][j*8 +: 8]
  //   else
  //     next_reg[i] = reg_q_o[i]

  // For read-only registers, they always expose reg_init_i and ignore writes

  // Let's compute the next value for each register

  // We'll use a combinational always block to compute next values

  // Actually, let's use a generate block with always_ff for each register

  // But we need to handle the byte-level strobes carefully

  // Let's create a function to compute the next value for a register given the current value, write data, and strobes

  // For simplicity, let's use a combinational block to compute the next state for all registers

  // We'll declare a combinational next-state vector

  // Since RegDataWidth can be up to 32 bits (or more), and NoApbRegs can be up to 32,
  // we'll use a generate block

  // Let's use a different approach: for each register, we compute the next value combinationally,
  // then use always_ff to update

  // Declare combinational next-state signals
  // We'll use a 2D array of reg_data_t for next state

  // Actually, let's just use a generate block with always_ff for each register

  // For each register i:
  //   always_ff @(posedge pclk_i or negedge preset_ni)
  //     if (!preset_ni)
  //       if (ReadOnly[i])
  //         reg_q_o[i] <= reg_init_i[i];
  //       else
  //         reg_q_o[i] <= '0;
  //     else if (write_en && (reg_index == i) && !ReadOnly[i])
  //       // Apply byte strobes
  //       for (int j = 0; j < RegBytes; j++)
  //         if (pstrb[j])
  //           reg_q_o[i][j*8 +: 8] <= pwdata[j*8 +: 8];
  //       // Unstrobed bytes retain their value (implicit in the for loop)
  //     else
  //       // No change
  //       ;

  // But we can't have a for loop inside always_ff in standard Verilog/SystemVerilog easily
  // Let's use a different approach

  // We'll compute the next value for the addressed register combinationally,
  // then use a mux to select which register to update

  // Let's compute the next value for the addressed register

  // For the addressed register (reg_index), compute the new value:
  //   new_val = reg_q_o[reg_index]
  //   for each byte j in 0..RegBytes-1:
  //     if (pstrb[j])
  //       new_val[j*8 +: 8] = pwdata[j*8 +: 8]

  // We can do this with a combinational block

  // Let's declare a combinational signal for the new value of the addressed register

  // Since reg_index is a variable, we need to be careful

  // Let's use a generate block to create the next-state logic

  // Actually, let's use a simpler approach: for each register, we'll have an always_ff block
  // that checks if it's the addressed register and applies the byte strobes

  // We'll use a generate block

  genvar gi;
  generate
    for (gi = 0; gi < NoApbRegs; gi++) begin : gen_reg
      always_ff @(posedge pclk_i or negedge preset_ni) begin
        if (!preset_ni) begin
          if (ReadOnly[gi])
            reg_q_o[gi] <= reg_init_i[gi];
          else
            reg_q_o[gi] <= '0;
        end else if (write_en && (reg_index == gi) && !ReadOnly[gi]) begin
          // Apply byte strobes
          // We need to update only the strobed bytes
          // For each byte position j in 0..RegBytes-1:
          //   if pstrb[j] is set, update that byte
          //   else keep the current value
          // We can do this with a loop, but in SystemVerilog we can use a for loop in always_ff
          for (int j = 0; j < RegBytes; j++) begin
            if (pstrb[j])
              reg_q_o[gi][j*8 +: 8] <= pwdata[j*8 +: 8];
          end
        end
      end
    end
  endgenerate

endmodule
