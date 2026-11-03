module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source domain: hold data when valid is asserted
  reg [WIDTH-1:0] src_data_hold;
  reg             src_valid_hold;

  // Destination domain: synchronized signals
  reg             dst_ack;
  reg             dst_ack_sync1;
  reg             dst_ack_sync2;

  // Destination domain: synchronized data
  reg [WIDTH-1:0] dst_data_sync1;
  reg [WIDTH-1:0] dst_data_sync2;

  // Destination domain: synchronized valid
  reg             dst_valid_sync1;
  reg             dst_valid_sync2;

  // Destination domain: output register
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;

  // Source domain: ready logic
  // src_ready is high when we are not holding a valid item that hasn't been acknowledged
  // We use a 2-phase handshake: src asserts valid, dst asserts ack
  // src_ready = ~src_valid_hold | dst_ack_sync2

  assign src_ready_o = ~src_valid_hold | dst_ack_sync2;

  // Source domain: capture data and valid when ready
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold  <= {WIDTH{1'b0}};
      src_valid_hold <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_hold  <= src_data_i;
        src_valid_hold <= 1'b1;
      end else if (dst_ack_sync2) begin
        // Acknowledged, clear valid
        src_valid_hold <= 1'b0;
      end
    end
  end

  // Destination domain: synchronize ack back to source
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_sync1 <= 1'b0;
      dst_ack_sync2 <= 1'b0;
    end else begin
      dst_ack_sync1 <= dst_ack;
      dst_ack_sync2 <= dst_ack_sync1;
    end
  end

  // Destination domain: synchronize data and valid from source
  // We need to synchronize the held data and valid signal
  // The data is stable while src_valid_hold is high
  // We synchronize src_valid_hold and src_data_hold

  // First, we need to detect when a new valid item arrives in the destination domain
  // We synchronize src_valid_hold
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync1 <= 1'b0;
      dst_valid_sync2 <= 1'b0;
    end else begin
      dst_valid_sync1 <= src_valid_hold;
      dst_valid_sync2 <= dst_valid_sync1;
    end
  end

  // Synchronize data - we capture data when valid transitions from 0 to 1 in the synchronized domain
  // But we need to ensure data is stable. Since data is held stable while valid is high,
  // we can synchronize data through 2 stages as well.
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync1 <= {WIDTH{1'b0}};
      dst_data_sync2 <= {WIDTH{1'b0}};
    end else begin
      dst_data_sync1 <= src_data_hold;
      dst_data_sync2 <= dst_data_sync1;
    end
  end

  // Destination domain: generate ack when we have a valid item and it's ready to be consumed
  // We assert ack when dst_valid_sync2 is high and dst_ready_i is high
  // This tells the source that the item has been accepted
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 1'b0;
    end else begin
      if (dst_valid_sync2 && dst_ready_i) begin
        dst_ack <= 1'b1;
      end else begin
        dst_ack <= 1'b0;
      end
    end
  end

  // Destination domain: output logic
  // dst_valid_o is high when we have a valid item that hasn't been consumed yet
  // We use dst_valid_sync2 as the indicator that a valid item is present
  // dst_data_o is the synchronized data
  // When dst_valid_o is high and dst_ready_i is low, we must hold the data stable

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      if (dst_valid_sync2) begin
        // A valid item is present in the synchronized domain
        if (dst_ready_i) begin
          // Item is being consumed, clear valid
          dst_valid_reg <= 1'b0;
        end else begin
          // Item is not ready, hold valid and data
          dst_valid_reg <= 1'b1;
          dst_data_reg  <= dst_data_sync2;
        end
      end else begin
        // No valid item
        dst_valid_reg <= 1'b0;
      end
    end
  end

  assign dst_valid_o = dst_valid_reg;
  assign dst_data_o  = dst_data_reg;

endmodule
