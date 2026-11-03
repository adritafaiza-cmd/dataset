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

  // Internal register file
  reg_data_t [NoApbRegs-1:0] reg_file;

  // Internal signals
  logic [NoApbRegs-1:0] reg_addr_match;
  logic [NoApbRegs-1:0] reg_write_enable;
  logic [NoApbRegs-1:0] reg_read_enable;
  logic [NoApbRegs-1:0] reg_write_mask;
  reg_data_t            reg_write_data;
  reg_data_t            reg_read_data;

  // Decode the address
  always_comb begin
    reg_addr_match = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      reg_addr_match[i] = (req_i.paddr[ApbAddrWidth-1:2] == (base_addr_i[ApbAddrWidth-1:2] + i * (AddrOffset / 4)));
    end
  end

  // Determine read and write enables
  always_comb begin
    reg_read_enable = '0;
    reg_write_enable = '0;
    if (req_i.psel && req_i.penable) begin
      reg_read_enable = reg_addr_match & ~req_i.pwrite;
      reg_write_enable = reg_addr_match & req_i.pwrite;
    end
  end

  // Generate write mask based on byte strobes
  always_comb begin
    reg_write_mask = '0;
    for (int i = 0; i < (ApbDataWidth / 8); i++) begin
      reg_write_mask[(i + 1) * (RegDataWidth / 8) - 1 -: (RegDataWidth / 8)] = {RegDataWidth / 8{req_i.pstrb[i]}};
    end
  end

  // Generate write data
  always_comb begin
    reg_write_data = '0;
    for (int i = 0; i < (ApbDataWidth / 8); i++) begin
      reg_write_data[(i + 1) * (RegDataWidth / 8) - 1 -: (RegDataWidth / 8)] = req_i.pwdata[i * (RegDataWidth / 8) +: (RegDataWidth / 8)];
    end
  end

  // Register file write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (!ReadOnly[i]) begin
          reg_file[i] <= '0;
        end else begin
          reg_file[i] <= reg_init_i[i];
        end
      end
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (reg_write_enable[i]) begin
          reg_file[i] <= (reg_file[i] & ~reg_write_mask) | (reg_write_data & reg_write_mask);
        end
      end
    end
  end

  // Register file read logic
  always_comb begin
    reg_read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (reg_read_enable[i]) begin
        reg_read_data = reg_file[i];
      end
    end
  end

  // Assign output response
  always_comb begin
    resp_o.prdata = reg_read_data;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

  // Assign register values output
  always_comb begin
    reg_q_o = reg_file;
  end

endmodule
