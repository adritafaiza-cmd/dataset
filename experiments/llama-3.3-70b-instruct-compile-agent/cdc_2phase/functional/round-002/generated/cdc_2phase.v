module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  logic [WIDTH-1:0] data;
  logic             valid;
  logic             ready;

  // Synchronize src_rst_ni to src_clk_i
  logic src_rst_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) src_rst_sync <= 1'b1;
    else src_rst_sync <= 1'b0;
  end

  // Synchronize dst_rst_ni to dst_clk_i
  logic dst_rst_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) dst_rst_sync <= 1'b1;
    else dst_rst_sync <= 1'b0;
  end

  // Gray code handshake
  logic [1:0] src_handshake;
  logic [1:0] dst_handshake;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_handshake <= 2'b00;
      src_ready_o   <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_handshake <= 2'b01;
        src_ready_o   <= 1'b0;
      end else if (src_handshake == 2'b01 && dst_handshake == 2'b10) begin
        src_handshake <= 2'b00;
        src_ready_o   <= 1'b1;
      end else if (src_handshake == 2'b00 && !valid) begin
        src_ready_o   <= 1'b1;
      end else begin
        src_ready_o   <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_handshake <= 2'b00;
      dst_valid_o   <= 1'b0;
    end else begin
      if (dst_valid_o && dst_ready_i) begin
        dst_handshake <= 2'b00;
        dst_valid_o   <= 1'b0;
      end else if (dst_handshake == 2'b00 && valid) begin
        dst_handshake <= 2'b10;
        dst_valid_o   <= 1'b1;
      end else if (dst_handshake == 2'b10 && !dst_ready_i) begin
        dst_valid_o   <= 1'b1;
      end else begin
        dst_valid_o   <= 1'b0;
      end
    end
  end

  // Data and valid signal synchronization
  logic [WIDTH-1:0] data_sync;
  logic             valid_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_sync <= '0;
      valid_sync <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        data_sync <= src_data_i;
        valid_sync <= 1'b1;
      end else if (dst_handshake == 2'b10) begin
        valid_sync <= 1'b0;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data <= '0;
      valid <= 1'b0;
    end else begin
      if (valid_sync && !valid) begin
        data <= data_sync;
        valid <= 1'b1;
      end else if (dst_valid_o && dst_ready_i) begin
        valid <= 1'b0;
      end
    end
  end

  assign dst_data_o = data;

endmodule
