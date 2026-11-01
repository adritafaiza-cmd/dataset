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

  // Source domain: request signal
  reg src_req;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain: acknowledge signal
  reg dst_ack;

  // Synchronizers
  reg [1:0] req_sync;
  reg [1:0] ack_sync;

  // Destination domain: data register and valid
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;

  // Synchronize src_req into destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      req_sync <= 2'b00;
    else
      req_sync <= {req_sync[0], src_req};
  end

  // Synchronize dst_ack into source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 2'b00;
    else
      ack_sync <= {ack_sync[0], dst_ack};
  end

  // Source domain logic
  // src_ready_o is high when we can accept a new item
  // We can accept when: not currently holding an item (src_req is low) OR the item has been acknowledged
  // Actually, let's think about this more carefully.
  
  // The protocol:
  // 1. Source asserts src_req when it has data to send and is ready to send.
  // 2. Destination sees src_req (synchronized) and latches the data, asserts dst_valid.
  // 3. When destination completes transfer (dst_valid & dst_ready), it asserts dst_ack.
  // 4. Source sees dst_ack (synchronized) and deasserts src_req, making src_ready_o high again.
  
  // But we need to be careful about the timing. Let's use a simpler approach:
  // - src_ready_o is high when src_req is low (no outstanding request)
  // - When src_valid_i & src_ready_o, we latch data and assert src_req
  // - When we see dst_ack (synchronized), we deassert src_req
  
  // Actually, let me reconsider. The two-phase handshake:
  // - Phase 1: Source asserts req, destination sees it, latches data, asserts valid
  // - Phase 2: Destination deasserts req (or source deasserts after ack), destination deasserts valid after ready
  
  // Let's use a standard two-phase CDC with a single bit request/acknowledge:
  // - src_req: asserted by source when it has data
  // - dst_ack: asserted by destination when it has accepted the data
  
  // Source domain:
  // - src_ready_o = !src_req (can accept new data when no outstanding request)
  // - When src_valid_i & src_ready_o: latch data, assert src_req
  // - When ack_sync[1] (synchronized dst_ack): deassert src_req
  
  // Destination domain:
  // - When req_sync[1] (synchronized src_req) and not already valid: latch data, assert dst_valid
  // - When dst_valid & dst_ready: assert dst_ack, deassert dst_valid
  // - When dst_ack is asserted and req_sync[1] is deasserted: deassert dst_ack
  
  // Wait, this is getting complex. Let me simplify.
  
  // Actually, for a two-phase handshake, the typical approach is:
  // - Source asserts req, waits for ack
  // - Destination asserts ack, waits for req to deassert
  // - Source deasserts req
  // - Destination deasserts ack
  
  // But we need to handle the data transfer. Let's use a simpler model:
  // - Source latches data and asserts src_req when src_valid_i & src_ready_o
  // - src_ready_o is high when src_req is low
  // - Destination, when it sees src_req (synchronized), latches data and asserts dst_valid
  // - When dst_valid & dst_ready, destination asserts dst_ack
  // - Source, when it sees dst_ack (synchronized), deasserts src_req
  // - Destination, when it sees src_req deasserted (synchronized), deasserts dst_ack
  
  // This should work. Let's implement it.

  // Source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_i && !src_req) begin
        src_data_reg <= src_data_i;
        src_req <= 1'b1;
      end else if (ack_sync[1]) begin
        src_req <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_req;

  // Destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      if (req_sync[1] && !dst_valid_reg) begin
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_ack <= 1'b1;
      end else if (dst_ack && !req_sync[1]) begin
        dst_ack <= 1'b0;
      end
    end
  end

  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
