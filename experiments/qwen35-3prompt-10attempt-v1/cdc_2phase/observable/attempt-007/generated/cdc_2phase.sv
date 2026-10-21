```systemverilog
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

  // Source side: Capture valid/ready handshake and data
  logic src_valid_reg;
  logic src_ready_reg;
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_next;
  logic src_ready_next;

  // Destination side: Capture valid/ready handshake and data
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_next;
  logic dst_ready_next;

  // Source Domain Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg  <= 1'b0;
      src_ready_reg  <= 1'b0;
      src_data_reg   <= '{default: 1'b0};
    end else begin
      // Capture incoming signals
      src_valid_reg  <= src_valid_i;
      src_ready_reg  <= src_ready_o; // Feedback loop for handshake
      src_data_reg   <= src_data_i;
    end
  end

  // Destination Domain Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg  <= 1'b0;
      dst_ready_reg  <= 1'b0;
      dst_data_reg   <= '{default: 1'b0};
    end else begin
      // Capture incoming signals
      dst_valid_reg  <= dst_valid_o; // Feedback loop for handshake
      dst_ready_reg  <= dst_ready_i;
      dst_data_reg   <= dst_data_o;
    end
  end

  // Cross-domain: Source -> Destination (Data and Valid)
  // We use a two-phase handshake. The source holds data until destination is ready.
  // The destination captures data when valid is asserted.

  // Source Side: Determine next state based on local ready and cross-domain ready
  always_comb begin
    src_ready_next = 1'b0;
    src_valid_next = src_valid_reg;

    if (!src_rst_ni) begin
      src_ready_next = 1'b0;
      src_valid_next = 1'b0;
    end else begin
      // Source is ready if it has data to send AND destination is ready
      // We assume src_ready_o drives the handshake signal back to the caller
      // But internally, we need to know if the destination is ready to accept the next item.
      // Since this is a 2-phase channel, we typically use a "pending" flag or direct feedback.
      // Let's implement the standard 2-phase:
      // 1. Source asserts valid (holds data).
      // 2. Destination asserts ready (captures data).
      // 3. Source deasserts valid.
      
      // To simplify the interface where src_ready_o is an output driven by the module:
      // The module should assert src_ready_o when it is ready to accept new data.
      // It is ready if src_valid_reg is low OR if the destination has acknowledged the current item.
      
      // However, the standard 2-phase implementation usually involves a "pending" flag in the destination
      // to tell the source "I am busy".
      
      // Let's refine the architecture:
      // Source holds data in src_data_reg when src_valid_reg is high.
      // Destination captures data into dst_data_reg when dst_valid_reg is high.
      
      // We need a mechanism to propagate "Destination Ready" back to Source.
      // Since we cannot add extra ports, we must rely on the existing handshake signals.
      // But wait, the problem asks for a 2-phase valid/ready channel.
      // Standard 2-phase:
      // Phase 1: Source asserts valid. Destination sees valid.
      // Phase 2: Destination asserts ready. Source sees ready.
      
      // Implementation Strategy:
      // 1. Source side:
      //    - If src_valid_i is high, we want to send.
      //    - We need to know if dst is ready.
      //    - Since we don't have a direct "dst_ready" input to the source domain,
      //      we must use the feedback path.
      //    - Actually, the standard way without extra wires is to use a "pending" flag in the destination
      //      that is visible to the source? No, that requires a wire.
      //      
      //    Let's re-read the requirement: "Move source data to the destination once and in order."
      //    "If the receiver is not ready, hold the pending item".
      //    
      //    This implies a standard handshake.
      //    The tricky part is crossing domains.
      //    
      //    Correct 2-phase approach with minimal wires:
      //    Source Domain:
      //      - Has src_valid_i (input)
      //      - Needs to drive src_ready_o (output)
      //      - Needs to know if dst is ready to accept the current item.
      //      
      //    Destination Domain:
      //      - Has dst_ready_i (input)
      //      - Needs to drive dst_valid_o (output)
      //      - Needs to know if src is ready to accept new data (to drive src_ready_o).
      //      
      //    Wait, the interface provided has:
      //      src_ready_o (output from source side)
      //      dst_ready_i (input to destination side)
      //      dst_valid_o (output from destination side)
      //      src_valid_i (input to source side)
      //      
      //    This is a standard handshake interface. The challenge is the CDC.
      //    We cannot simply cross src_ready_o to dst domain or dst_ready_i to src domain directly 
      //    without synchronization, because they are on different clocks.
      //    
      //    Standard Solution for 2-phase handshake across clocks:
      //    1. Source Domain:
      //       - Captures src_valid_i.
      //       - Captures dst_ready_i (synchronized).
      //       - If (src_valid_i && dst_ready_i_synced), then assert src_ready_o.
      //       - But src_ready_o must be stable long enough for dst to see it.
      //       - Actually, the handshake is:
      //         Source asserts valid -> Dest captures valid -> Dest asserts ready -> Source captures ready.
      //         
      //    Let's build the state machines properly.
    
    // Source Side State Machine
    // State: IDLE, WAIT_DST_READY
    // Inputs: src_valid_i, dst_ready_i (synchronized)
    // Outputs: src_ready_o
    
    // We need to synchronize dst_ready_i into the source clock domain.
    logic [1:0] dst_ready_sync;
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) dst_ready_sync <= 2'b00;
      else dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end

    always_comb begin
      src_ready_o = 1'b0;
      if (!src_rst_ni) begin
        src_ready_o = 1'b0;
        src_valid_next = 1'b0;
      end else begin
        // Logic:
        // If we have data to send (src_valid_reg is high) and destination is ready (dst_ready_sync[1]),
        // then we assert src_ready_o.
        // Note: In a 2-phase handshake, the source asserts valid, then waits for ready.
        // Once ready is received, the source deasserts valid.
        
        // However, the interface defines src_valid_i as input and src_ready_o as output.
        // This suggests the external caller drives src_valid_i and reads src_ready_o.
        // The module should assert src_ready_o when it is ready to accept new data.
        // It is ready if:
        // 1. It is not currently holding data (src_valid_reg == 0)
        // 2. OR it has data but destination is ready (dst_ready_sync[1] == 1)
        
        // Wait, if src_valid_reg is 1, it means we are in the middle of a transfer.
        // We should NOT assert src_ready_o to the caller to accept NEW data until the current transfer is done.
        // So src_ready_o should be 0 while src_valid_reg is 1 AND dst_ready is not yet received.
        // Once dst_ready is received, src_valid_reg becomes 0, and src_ready_o becomes 1.
        
        if (src_valid_reg && dst_ready_sync[1]) begin
          // Destination is ready. We will deassert valid next cycle.
          // But we must ensure we don't accept new data yet.
          // Actually, once dst_ready is seen, we can immediately deassert valid.
          // So src_ready_o should be 1 only if src_valid_reg is 0.
          src_ready_o = 1'b0; 
          src_valid_next = 1'b0; // Deassert valid immediately after seeing ready
        end else if (!src_valid_reg) begin
          // No data pending, ready to accept new data
          src_ready_o = 1'b1;
          src_valid_next = src_valid_i; // Capture new valid
        end else begin
          // Holding data, waiting for ready
          src_ready_o = 1'b0;
          src_valid_next = src_valid_reg; // Keep holding
        end
      end
    end

    // Destination Side State Machine
    // Inputs: dst_valid_i (synchronized), dst_ready_i
    // Outputs: dst_valid_o, dst_data_o
    
    // We need to synchronize dst_valid_i into the destination clock domain.
    logic [1:0] src_valid_sync;
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni) src_valid_sync <= 2'b00;
      else src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end

    always_comb begin
      dst_valid_o = 1'b0;
      dst_data_o = '{default: 1'b0};
      
      if (!dst_rst_ni) begin
        dst_valid_o = 1'b0;
        dst_data_o = '{default: 1'b0};
      end else begin
        // Logic:
        // If we have data to send (dst_valid_reg is high) and source is ready (src_valid_sync[1] == 1),
        // then we assert dst_valid_o.
        // Wait, the handshake is:
        // 1. Source asserts valid (src_valid_i goes high).
        // 2. Destination sees valid (src_valid_sync[1] goes high).
        // 3. Destination asserts ready (dst_valid_o goes high).
        // 4. Source sees ready (dst_ready_i goes high).
        // 5. Source deasserts valid.
        
        // So in Destination Domain:
        // If src_valid_sync[1] is high, we assert dst_valid_o.
        // We hold dst_valid_o until we see dst_ready_i? 
        // No, the standard 2-phase is:
        // Source: valid -> (wait for ready) -> !valid
        // Dest:  valid -> (assert ready) -> !valid
        
        // Let's trace:
        // Cycle 1: src_valid_i=1. src_valid_sync[1]=1.
        //          dst_valid_o should be 1.
        // Cycle 2: dst_ready_i=1.
        //          src_ready_o should be 1 (in source domain).
        //          src_valid_next = 0.
        // Cycle 3: src_valid_i=0. src_valid_sync[1]=0.
        //          dst_valid_o should be 0.
        
        // So:
        if (src_valid_sync[1]) begin
          dst_valid_o = 1'b1;
          dst_data_o = dst_data_reg;
        end else begin
          dst_valid_o = 1'b0;
          dst_data_o = '{default: 1'b0};
        end
      end
    end

    // Update registers in Source Domain
    always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
      if (!src_rst_ni) begin
        src_valid_reg <= 1'b0;
        src_data_reg  <= '{default: 1'b0};
      end else begin
        src_valid_reg <= src_valid_next;
        // Data is captured when valid is asserted. 
        // We capture src_data_i when src_valid_i is high.
        if (src_valid_i) begin
          src_data_reg <= src_data_i;
        end
      end
    end

    // Update registers in Destination Domain
    always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
      if (!dst_rst_ni) begin
        dst_valid_reg <= 1'b0;
        dst_data_reg  <= '{default: 1'b0};
      end else begin
        dst_valid_reg <= dst_valid_next;
        // Data is captured when valid is asserted.
        // We capture dst_data_o (which is the data from source) when dst_valid_i is high.
        // But wait, dst_data_o is driven by the logic above.
        // We need to capture the data when the handshake completes?
        // No, in 2-phase, the data is valid when dst_valid_o is high.
        // So we capture dst_data_o when dst_valid_i is high.
        if (dst_valid_i) begin
          dst_data_reg <= dst_data_o;
        end
      end
    end

  endmodule
```<|im_end|>
