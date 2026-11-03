module apb_regs #(
  parameter int unsigned        NoApbRegs    = 32'd32,
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
  apb_addr_t                 reg_addr;
  apb_addr_t                 reg_offset;
  logic                      write_enable;
  logic                      read_enable;
  logic [ApbDataWidth/8-1:0] byte_strobe;
  reg_data_t                 write_data;
  reg_data_t                 read_data;
  logic [$clog2(NoApbRegs)-1:0] reg_index;
  reg_data_t                 reg_write_data;

  // Decode the register address
  assign reg_offset = base_addr_i;
  assign reg_addr = req_i.addr - reg_offset;
  assign reg_index = reg_addr / AddrOffset;

  // Determine if the current address is within the register range
  logic addr_valid;
  assign addr_valid = (reg_addr >= reg_offset) && (reg_addr < reg_offset + NoApbRegs * AddrOffset);

  // Assign byte strobe
  assign byte_strobe = req_i.strb;

  // Assign write data
  assign write_data = req_i.wdata;

  // Determine read and write enables
  assign read_enable = req_i.psel && req_i.penable && !req_i.write;
  assign write_enable = req_i.psel && req_i.penable && req_i.write && addr_valid;

  // Generate response
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

  // Read data
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      read_data <= '0;
    end else if (read_enable) begin
      if (ReadOnly[reg_index]) begin
        read_data <= reg_init_i[reg_index];
      end else begin
        read_data <= reg_file[reg_index];
      end
    end
  end

  // Write data
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_file <= '0;
    end else if (write_enable) begin
      if (!ReadOnly[reg_index]) begin
        for (int i = 0; i < ApbDataWidth/8; i++) begin
          if (byte_strobe[i]) begin
            reg_write_data[i*8 +: 8] <= write_data[i*8 +: 8];
          end else begin
            reg_write_data[i*8 +: 8] <= reg_file[reg_index][i*8 +: 8];
          end
        end
        reg_file[reg_index] <= reg_write_data;
      end
    end
  end

  // Drive output register values
  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      reg_q_o <= '0;
    end else begin
      for (int i = 0; i < NoApbRegs; i++) begin
        if (ReadOnly[i]) begin
          reg_q_o[i] <= reg_init_i[i];
        end else begin
          reg_q_o[i] <= reg_file[i];
        end
      end
    end
  end

endmodule
