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

  // Source domain: handshake signal to destination
  // req: source requests a transfer (set when valid & ready, cleared when ack)
  // We use a 2-phase toggle scheme for CDC.

  // Source domain registers
  reg [WIDTH-1:0] src_data_reg;
  reg             src_req;      // toggle signal: 0->1 means new request
  reg             src_ack;      // toggle signal from destination (synchronized)

  // Destination domain registers
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_req_sync1;
  reg             dst_req_sync2;
  reg             dst_req;      // synchronized version of src_req
  reg             dst_ack;      // toggle signal back to source
  reg             dst_ack_sync1;
  reg             dst_ack_sync2;
  reg             dst_ack_src;  // synchronized version of dst_ack in source domain

  // Source domain: synchronize dst_ack back
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync1 <= 1'b0;
      dst_ack_sync2 <= 1'b0;
      dst_ack_src   <= 1'b0;
    end else begin
      dst_ack_sync1 <= dst_ack;
      dst_ack_sync2 <= dst_ack_sync1;
      dst_ack_src   <= dst_ack_sync2;
    end
  end

  // Source domain: manage src_req and src_data_reg
  // src_req toggles when a new item is accepted (valid & ready)
  // src_ready is high when we can accept a new item:
  //   - No outstanding item: src_req == dst_ack_src (both at same toggle state, meaning no pending)
  //   - Or the previous item has been acknowledged: dst_ack_src has toggled to match src_req
  //
  // Let's think about this more carefully with a 2-phase toggle:
  //
  // State: src_req and dst_ack_src are both toggles.
  // When src_req == dst_ack_src: no outstanding transfer (idle or completed)
  // When src_req != dst_ack_src: outstanding transfer in flight
  //
  // src_ready_o = (src_req == dst_ack_src)
  //
  // On acceptance (src_valid_i & src_ready_o):
  //   src_data_reg <= src_data_i
  //   src_req <= ~src_req  (toggle)
  //
  // Destination sees the toggle on dst_req (synchronized src_req).
  // When dst_req changes, it latches data and toggles dst_ack.
  //
  // But wait: the data must be stable when the request is made.
  // Since we latch src_data_i into src_data_reg on acceptance, and the
  // request toggle happens at the same time, the data is stable before
  // the toggle propagates. Good.

  assign src_ready_o = (src_req == dst_ack_src);

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_req      <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_req      <= ~src_req;
      end
    end
  end

  // Destination domain: synchronize src_req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1 <= 1'b0;
      dst_req_sync2 <= 1'b0;
      dst_req       <= 1'b0;
    end else begin
      dst_req_sync1 <= src_req;
      dst_req_sync2 <= dst_req_sync1;
      dst_req       <= dst_req_sync2;
    end
  end

  // Destination domain: detect toggle on dst_req
  // When dst_req changes, a new item has arrived.
  // Latch the data and toggle dst_ack.

  reg dst_req_prev;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_prev <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_ack      <= 1'b0;
    end else begin
      dst_req_prev <= dst_req;
      if (dst_req != dst_req_prev) begin
        dst_data_reg <= src_data_reg;  // data is stable at this point
        dst_ack      <= ~dst_ack;
      end
    end
  end

  // Destination domain: synchronize dst_ack back to source
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_sync1 <= 1'b0;
      dst_ack_sync2 <= 1'b0;
    end else begin
      dst_ack_sync1 <= dst_ack;
      dst_ack_sync2 <= dst_ack_sync1;
    end
  end

  // Destination output: valid when there is an outstanding item
  // dst_valid_o is high when dst_req != dst_ack (in destination domain terms)
  // But we need to track this properly.

  // Let's track: dst_valid is high when a new item has been received but not yet consumed.
  // We can use: dst_valid_o = (dst_req != dst_ack)
  // But dst_ack is in dst domain, dst_req is in dst domain. Good.

  assign dst_valid_o = (dst_req != dst_ack);
  assign dst_data_o  = dst_data_reg;

endmodule
