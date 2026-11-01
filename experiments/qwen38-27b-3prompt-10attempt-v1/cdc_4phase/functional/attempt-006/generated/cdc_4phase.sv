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

  // Source domain signals
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_int;
  reg             src_ack_reg;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ack_reg;

  // Synchronizers
  // src_valid to dst domain
  reg [2:0] src_valid_sync;
  // src_data to dst domain (only valid when src_valid is high)
  reg [WIDTH-1:0] src_data_sync;
  // dst_ack to src domain
  reg [2:0] dst_ack_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg  <= {WIDTH{1'b0}};
      src_ack_reg   <= 1'b0;
      src_ready_int <= 1'b1;
    end else begin
      // Check if destination has acknowledged
      if (dst_ack_sync[2]) begin
        src_ack_reg <= 1'b1;
      end else begin
        src_ack_reg <= 1'b0;
      end

      // Accept new data if valid and ready
      if (src_valid_i && src_ready_int) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
      end

      // Clear valid when acknowledged
      if (src_valid_reg && dst_ack_sync[2]) begin
        src_valid_reg <= 1'b0;
      end

      // Ready logic
      if (DECOUPLED) begin
        // In decoupled mode, source can accept new data even if previous
        // hasn't been fully acknowledged, as long as we're not currently
        // sending (i.e., src_valid_reg is low or we just got ack)
        if (src_valid_reg && !dst_ack_sync[2]) begin
          src_ready_int <= 1'b0;
        end else begin
          src_ready_int <= 1'b1;
        end
      end else begin
        // In non-decoupled mode, source must wait for full handshake
        if (src_valid_reg) begin
          src_ready_int <= 1'b0;
        end else begin
          src_ready_int <= 1'b1;
        end
      end
    end
  end

  assign src_ready_o = src_ready_int;

  // Synchronize src_valid to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 3'b000;
    end else begin
      src_valid_sync <= {src_valid_sync[1:0], src_valid_reg};
    end
  end

  // Synchronize src_data to destination domain
  // We need to capture data when valid is asserted
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      // Capture data when valid transitions from 0 to 1 in the sync domain
      if (src_valid_sync[1] && !src_valid_sync[0]) begin
        // This is a rising edge in the synchronized valid signal
        // But we need the actual data, which we can't directly sync
        // We'll use a different approach: sync the data along with valid
      end
    end
  end

  // Better approach: Use a data synchronizer that captures data
  // when the valid signal is high in the source domain
  // We'll synchronize the data using a multi-bit synchronizer
  // but only update when valid is asserted

  // Let's use a different strategy:
  // In the source domain, when we accept data, we set a "data_valid" flag
  // and the data. We synchronize both.
  // Actually, for a 4-phase handshake, we can use the following approach:
  // 
  // Source: 
  //   - When ready and valid, latch data, assert valid
  //   - Wait for ack
  //   - Deassert valid
  //   - Wait for ack deassert
  //   - Ready again
  //
  // Destination:
  //   - When valid is high, latch data, assert valid to downstream
  //   - Wait for ready
  //   - Deassert valid
  //   - Assert ack
  //   - Wait for valid deassert
  //   - Deassert ack
  //   - Ready again

  // Let me redesign with proper 4-phase handshake

  // Source domain
  reg [WIDTH-1:0] src_data_latch;
  reg             src_valid_latch;
  reg             src_ack_latch;
  reg             src_ready_latch;

  // Destination domain
  reg [WIDTH-1:0] dst_data_latch;
  reg             dst_valid_latch;
  reg             dst_ack_latch;

  // Synchronizers
  reg [2:0] src_valid_sync;
  reg [2:0] src_ack_sync;
  reg [WIDTH-1:0] src_data_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_latch <= 1'b0;
      src_data_latch  <= {WIDTH{1'b0}};
      src_ack_latch   <= 1'b0;
      src_ready_latch <= 1'b1;
    end else begin
      // Synchronize dst_ack
      if (dst_ack_sync[2]) begin
        src_ack_latch <= 1'b1;
      end else begin
        src_ack_latch <= 1'b0;
      end

      // State machine for 4-phase handshake
      if (!src_valid_latch) begin
        // Idle state: ready to accept
        if (src_valid_i && src_ready_latch) begin
          src_data_latch  <= src_data_i;
          src_valid_latch <= 1'b1;
        end
        src_ready_latch <= 1'b1;
      end else begin
        // Valid asserted: wait for ack
        if (src_ack_latch) begin
          src_valid_latch <= 1'b0;
        end
        src_ready_latch <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready_latch;

  // Synchronize src_valid to destination
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 3'b000;
    end else begin
      src_valid_sync <= {src_valid_sync[1:0], src_valid_latch};
    end
  end

  // Synchronize src_data to destination
  // We need to capture data when valid is high
  // Use a data synchronizer that updates when valid is high
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      // Update data when valid is high in the synchronized domain
      // This is a simple approach: always sync the data
      // But we need to ensure data is stable when valid is high
      // Since source holds data stable while valid is high,
      // we can just synchronize the data
      src_data_sync <= src_data_latch;
    end
  end

  // Synchronize dst_ack to source
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_sync <= 3'b000;
    end else begin
      dst_ack_sync <= {dst_ack_sync[1:0], dst_ack_latch};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_latch <= 1'b0;
      dst_data_latch  <= {WIDTH{1'b0}};
      dst_ack_latch   <= 1'b0;
    end else begin
      if (!dst_valid_latch) begin
        // Idle state: wait for valid from source
        if (src_valid_sync[2]) begin
          dst_data_latch  <= src_data_sync;
          dst_valid_latch <= 1'b1;
        end
        dst_ack_latch <= 1'b0;
      end else begin
        // Valid asserted: wait for ready
        if (dst_ready_i) begin
          dst_valid_latch <= 1'b0;
          dst_ack_latch   <= 1'b1;
        end else begin
          dst_ack_latch <= 1'b0;
        end
      end
    end
  end

  assign dst_data_o  = dst_data_latch;
  assign dst_valid_o = dst_valid_latch;

endmodule
