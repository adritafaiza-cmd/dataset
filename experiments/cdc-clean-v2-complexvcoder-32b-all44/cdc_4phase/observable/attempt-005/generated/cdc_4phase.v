module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Instantiate the four-phase handshake module
  cdc_4phase_handshake handshake_inst (
    .clk_src    (src_clk_i),
    .rst_src_ni (src_rst_ni),
    .valid_src  (src_valid_i),
    .ready_src  (src_ready_o),
    .clk_dst    (dst_clk_i),
    .rst_dst_ni (dst_rst_ni),
    .valid_dst  (dst_valid_o),
    .ready_dst  (dst_ready_i)
  );

  // Instantiate the FIFO module
  cdc_fifo #(
    .WIDTH (WIDTH)
  ) fifo_inst (
    .clk_wr    (src_clk_i),
    .rst_wr_ni (src_rst_ni),
    .data_wr   (src_data_i),
    .wr_en     (handshake_inst.ready_src),
    .clk_rd    (dst_clk_i),
    .rst_rd_ni (dst_rst_ni),
    .rd_en     (dst_ready_i),
    .data_rd   (dst_data_o),
    .empty     (handshake_inst.valid_dst)
  );

endmodule

module cdc_4phase_handshake (
  input  clk_src,
  input  rst_src_ni,
  input  valid_src,
  output ready_src,
  input  clk_dst,
  input  rst_dst_ni,
  output valid_dst,
  input  ready_dst
);

  reg [1:0] phase_src;
  reg [1:0] phase_dst;
  reg       req_src;
  reg       req_dst;

  // Source side logic
  always @(posedge clk_src or negedge rst_src_ni) begin
    if (!rst_src_ni) begin
      phase_src <= 2'b00;
      req_src   <= 1'b0;
    end else begin
      case (phase_src)
        2'b00: begin
          if (valid_src && !req_src) begin
            phase_src <= 2'b01;
            req_src   <= 1'b1;
          end
        end
        2'b01: begin
          if (phase_dst == 2'b10) begin
            phase_src <= 2'b10;
          end
        end
        2'b10: begin
          if (phase_dst == 2'b11) begin
            phase_src <= 2'b11;
          end
        end
        2'b11: begin
          if (phase_dst == 2'b00) begin
            phase_src <= 2'b00;
            req_src   <= 1'b0;
          end
        end
        default: phase_src <= 2'b00;
      endcase
    end
  end

  assign ready_src = (phase_src == 2'b00) && !req_src;

  // Destination side logic
  always @(posedge clk_dst or negedge rst_dst_ni) begin
    if (!rst_dst_ni) begin
      phase_dst <= 2'b00;
      req_dst   <= 1'b0;
    end else begin
      case (phase_dst)
        2'b00: begin
          if (phase_src == 2'b01) begin
            phase_dst <= 2'b01;
            req_dst   <= 1'b1;
          end
        end
        2'b01: begin
          if (phase_src == 2'b10 && ready_dst) begin
            phase_dst <= 2'b10;
          end
        end
        2'b10: begin
          if (phase_src == 2'b11) begin
            phase_dst <= 2'b11;
          end
        end
        2'b11: begin
          if (phase_src == 2'b00) begin
            phase_dst <= 2'b00;
            req_dst   <= 1'b0;
          end
        end
        default: phase_dst <= 2'b00;
      endcase
    end
  end

  assign valid_dst = (phase_dst == 2'b01) && req_dst;

endmodule

module cdc_fifo #(
  parameter WIDTH = 1
)(
  input  clk_wr,
  input  rst_wr_ni,
  input  [WIDTH-1:0] data_wr,
  input  wr_en,
  input  clk_rd,
  input  rst_rd_ni,
  input  rd_en,
  output [WIDTH-1:0] data_rd,
  output empty
);

  localparam DEPTH = 4;
  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [ADDR_WIDTH-1:0] wr_ptr;
  reg [ADDR_WIDTH-1:0] rd_ptr;
  reg [ADDR_WIDTH-1:0] wr_ptr_gray;
  reg [ADDR_WIDTH-1:0] rd_ptr_gray;
  reg [ADDR_WIDTH-1:0] rd_ptr_gray_sync;

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_wr_ni) begin
    if (!rst_wr_ni) begin
      wr_ptr <= 0;
    end else if (wr_en) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  assign wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_rd_ni) begin
    if (!rst_rd_ni) begin
      rd_ptr <= 0;
    end else if (rd_en && !empty) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Synchronize write pointer gray code to read domain
  always @(posedge clk_rd or negedge rst_rd_ni) begin
    if (!rst_rd_ni) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Binary conversion of synchronized write pointer
  function [ADDR_WIDTH-1:0] gray_to_bin;
    input [ADDR_WIDTH-1:0] gray;
    reg [ADDR_WIDTH-1:0] bin;
    integer i;
    begin
      bin[ADDR_WIDTH-1] = gray[ADDR_WIDTH-1];
      for (i = ADDR_WIDTH-2; i >= 0; i = i - 1) begin
        bin[i] = bin[i+1] ^ gray[i];
      end
      gray_to_bin = bin;
    end
  endfunction

  assign rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;

  // FIFO memory write
  always @(posedge clk_wr) begin
    if (wr_en) begin
      mem[wr_ptr] <= data_wr;
    end
  end

  // FIFO memory read
  assign data_rd = mem[rd_ptr];

  // FIFO empty and full flags
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray);

endmodule
