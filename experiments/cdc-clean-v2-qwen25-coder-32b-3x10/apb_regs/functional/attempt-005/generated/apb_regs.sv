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
  logic [NoApbRegs-1:0] addr_match;
  logic [NoApbRegs-1:0] write_enable;
  logic [NoApbRegs-1:0] read_enable;
  logic [RegDataWidth-1:0] write_data;
  logic [RegDataWidth-1:0] read_data;
  logic [ApbDataWidth/8-1:0] byte_strobe;

  // Decode the address
  always_comb begin
    addr_match = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      addr_match[i] = (req_i.paddr[ApbAddrWidth-1:2] == (base_addr_i[ApbAddrWidth-1:2] + i * (AddrOffset / 4)));
    end
  end

  // Determine write and read enables
  always_comb begin
    write_enable = '0;
    read_enable = '0;
    if (req_i.psel && req_i.penable && req_i.pwrite) begin
      write_enable = addr_match & req_i.pstrb;
    end else if (req_i.psel && req_i.penable && !req_i.pwrite) begin
      read_enable = addr_match;
    end
  end

  // Byte strobe handling
  always_comb begin
    byte_strobe = req_i.pstrb;
  end

  // Write data handling
  always_comb begin
    write_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (write_enable[i]) begin
        for (int j = 0; j < ApbDataWidth/8; j++) begin
          if (byte_strobe[j]) begin
            write_data[j*8 +: 8] = req_i.pwdata[j*8 +: 8];
          end else begin
            write_data[j*8 +: 8] = reg_file[i][j*8 +: 8];
          end
        end
      end
    end
  end

  // Read data handling
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (read_enable[i]) begin
        read_data = reg_file[i];
      end
    end
  end

  // Register file update
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
        if (write_enable[i] && !ReadOnly[i]) begin
          reg_file[i] <= write_data;
        end
      end
    end
  end

  // Output current register values
  always_comb begin
    for (int i = 0; i < NoApbRegs; i++) begin
      if (ReadOnly[i]) begin
        reg_q_o[i] = reg_init_i[i];
      end else begin
        reg_q_o[i] = reg_file[i];
      end
    end
  end

  // APB response
  always_comb begin
    resp_o.prdata = read_data;
    resp_o.pready = 1'b1;
    resp_o.pslverr = 1'b0;
  end

endmodule
