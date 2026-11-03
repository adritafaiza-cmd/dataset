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
  logic [ApbAddrWidth-1:0] addr;
  logic [NoApbRegs-1:0]    addr_match;
  logic [ApbDataWidth-1:0] write_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  logic                    write_enable;
  logic                    read_enable;

  // Decode the address
  always_comb begin
    addr = req_i.paddr - base_addr_i;
    addr_match = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      addr_match[i] = (addr == i * AddrOffset);
    end
  end

  // Determine read and write enables
  always_comb begin
    read_enable = req_i.psel && req_i.penable && !req_i.pwrite;
    write_enable = req_i.psel && req_i.penable && req_i.pwrite;
    byte_strobe = req_i.pstrb;
    write_data = req_i.pwdata;
  end

  // Register file write logic
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_file[i] <= reg_init_i[i];
        end else begin
          reg_file[i] <= '0;
        end
      end
    end else if (write_enable) begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (addr_match[i] && !ReadOnly[i]) begin
          for (int b = 0; b < ApbDataWidth/8; b++) begin
            if (byte_strobe[b]) begin
              reg_file[i][b*8 +: 8] <= write_data[b*8 +: 8];
            end
          end
        end
      end
    end
  end

  // Register file read logic
  always_comb begin
    resp_o.prdata = '0;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr_match[i] && read_enable) begin
        resp_o.prdata = reg_file[i];
      end
    end
  end

  // Output current register values
  always_comb begin
    reg_q_o = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = reg_file[i];
      end
    end
  end

endmodule
