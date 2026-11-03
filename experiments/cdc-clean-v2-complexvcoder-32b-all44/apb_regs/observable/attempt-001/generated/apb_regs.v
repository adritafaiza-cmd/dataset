module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd8,
  parameter int unsigned        ApbAddrWidth = 32'd32,
  parameter int unsigned        AddrOffset   = 32'd4,
  parameter int unsigned        ApbDataWidth = 32'd32,
  parameter int unsigned        RegDataWidth = 32'd32,
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

  // Internal signals
  reg_data_t [NoApbRegs-1:0] reg_file;
  logic [NoApbRegs-1:0]      addr_decoded;
  reg_data_t                 write_data;
  logic [ApbDataWidth/8-1:0] write_strobe;
  reg_data_t                 read_data;
  logic                      write_enable;
  logic                      read_enable;

  // Address decoding
  always_comb begin
    addr_decoded = '0;
    if (req_i) begin
      logic [ApbAddrWidth-1:0] addr_offset = base_addr_i & ~(AddrOffset - 1);
      for (int i = 0; i < NoApbRegs; i++) begin
        if (addr_offset == (i * AddrOffset)) begin
          addr_decoded[i] = 1'b1;
        end
      end
    end
  end

  // Write enable and read enable
  assign write_enable = req_i && req_i.psel && req_i.penable && req_i.pwrite;
  assign read_enable  = req_i && req_i.psel && !req_i.penable && !req_i.pwrite;

  // Write data handling
  assign write_data = req_i.pwdata;
  assign write_strobe = req_i.pstrb;

  // Register file read and write logic
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
      if (write_enable) begin
        for (int i = 0; i < NoApbRegs; i++) begin
          if (addr_decoded[i] && !ReadOnly[i]) begin
            for (int byte_idx = 0; byte_idx < ApbDataWidth/8; byte_idx++) begin
              if (write_strobe[byte_idx]) begin
                reg_file[i][(byte_idx+1)*8-1 -: 8] <= write_data[(byte_idx+1)*8-1 -: 8];
              end
            end
          end
        end
      end
    end
  end

  // Read data logic
  always_comb begin
    read_data = '0;
    for (int i = 0; i < NoApbRegs; i++) begin
      if (addr_decoded[i]) begin
        if (ReadOnly[i]) begin
          read_data = reg_init_i[i];
        end else begin
          read_data = reg_file[i];
        end
      end
    end
  end

  // Response signal
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      resp_o <= 1'b0;
    end else begin
      if (req_i.psel && req_i.penable) begin
        resp_o <= 1'b1;
      end else begin
        resp_o <= 1'b0;
      end
    end
  end

  // Output register file
  assign reg_q_o = reg_file;

endmodule
