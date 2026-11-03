module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd32,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32,
  parameter int unsigned        RegDataWidth = 32'd32,
  parameter bit [NoApbRegs-1:0] ReadOnly     = 32'h0,
  parameter type                req_t        = logic,
  parameter type                resp_t       = logic,
  parameter type                apb_addr_t   = logic[ApbAddrWidth-1:0],
  parameter type                reg_data_t   = logic[RegDataWidth-1:0]
) (
  input  logic                      pclk_i,
  input  logic                      preset_ni,
  input  req_t                      req_i,
  output resp_t                     resp_o,
  input  apb_addr_t                 base_addr_i,
  input  reg_data_t [NoApbRegs-1:0] reg_init_i,
  output reg_data_t [NoApbRegs-1:0] reg_q_o
);

  // Internal signals
  reg_data_t [NoApbRegs-1:0] reg_file;
  reg_data_t                 write_data;
  logic [NoApbRegs-1:0]      write_enable;
  reg_data_t                 read_data;
  apb_addr_t                 reg_addr;
  logic [$clog2(NoApbRegs)-1:0] reg_index;

  // Decode the APB address to find the register index
  assign reg_addr = req_i.paddr - base_addr_i;
  assign reg_index = reg_addr / AddrOffset;

  // Determine read data
  always_comb begin
    if (reg_index < NoApbRegs && ReadOnly[reg_index]) begin
      read_data = reg_init_i[reg_index];
    end else if (reg_index < NoApbRegs) begin
      read_data = reg_file[reg_index];
    end else begin
      read_data = '0;
    end
  end

  // Determine write enable
  always_comb begin
    write_enable = '0;
    if (req_i.psel && req_i.penable && reg_index < NoApbRegs && !ReadOnly[reg_index]) begin
      write_enable[reg_index] = 1'b1;
    end
  end

  // Generate write data considering byte strobes
  always_comb begin
    write_data = '0;
    for (int i = 0; i < ApbDataWidth / 8; i++) begin
      if (req_i.pstrb[i]) begin
        write_data[8*(i+1)-1:8*i] = req_i.pwdata[8*(i+1)-1:8*i];
      end
    end
  end

  // Register file logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (write_enable[i]) begin
          reg_file[i] <= (reg_file[i] & ~({ApbDataWidth{req_i.pstrb}})) | (write_data & {ApbDataWidth{req_i.pstrb}});
        end
      end
    end
  end

  // Assign outputs
  assign resp_o.prdata = read_data;
  assign resp_o.pready = 1'b1; // Always ready for simplicity
  assign resp_o.pslverr = 1'b0; // No error support

  // Drive reg_q_o with current register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= reg_init_i;
    end else begin
      reg_q_o <= reg_file;
    end
  end

endmodule
