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

  // Internal signals
  wire [WIDTH-1:0] src_data_reg;
  wire src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire [WIDTH-1:0] dst_data_int;

  // Source domain: register input data and valid
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination domain: register output data and valid
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;

  // Handshake signals
  // req: source -> destination (synchronized)
  // ack: destination -> source (synchronized)
  wire req;
  wire ack;

  // Source domain: generate request when valid and ready
  // The request is asserted when we have data to send and the previous ack has been received
  // For simplicity, use a simple 2-phase handshake with synchronization

  // Source side:
  // - When src_valid_i is high and src_ready_o is high, capture data and assert req
  // - Wait for ack to deassert req
  // - src_ready_o is high when we are not in the middle of a transfer (i.e., req is low or ack is high)

  // Let's use a standard 2-phase handshake:
  // req goes high when source has data
  // ack goes high when destination has received data
  // req goes low when source sees ack high
  // ack goes low when destination sees req low

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
    end else begin
      if (src_valid_i && src_ready_r) begin
        // Accept new data
        src_data_r <= src_data_i;
        src_valid_r <= 1'b1;
        src_ready_r <= 1'b0;
      end else if (src_valid_r && ack) begin
        // Ack received, transfer complete
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b1;
      end
    end
  end

  // Request signal: high when source has valid data waiting
  assign req = src_valid_r;

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
    end else begin
      if (req && !dst_valid_r) begin
        // New request, capture data
        dst_data_r <= src_data_r;
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        // Destination ready, complete transfer
        dst_valid_r <= 1'b0;
      end
    end
  end

  // Ack signal: high when destination has valid data
  assign ack = dst_valid_r;

  // Synchronize req from source to destination
  reg [1:0] req_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], req};
    end
  end
  wire req_dst = req_sync[1];

  // Synchronize ack from destination to source
  reg [1:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], ack};
    end
  end
  wire ack_src = ack_sync[1];

  // Override the local signals with synchronized versions
  // Actually, we need to use the synchronized signals in the logic above
  // Let me restructure

  // Source domain: use ack_src (synchronized ack)
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
    end else begin
      if (src_valid_i && src_ready_r) begin
        src_data_r <= src_data_i;
        src_valid_r <= 1'b1;
        src_ready_r <= 1'b0;
      end else if (src_valid_r && ack_src) begin
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b1;
      end
    end
  end

  // Destination domain: use req_dst (synchronized req)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
    end else begin
      if (req_dst && !dst_valid_r) begin
        dst_data_r <= src_data_r;
        dst_valid_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        dst_valid_r <= 1'b0;
      end
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_r;
  assign dst_data_o = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
