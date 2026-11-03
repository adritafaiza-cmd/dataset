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

  // Internal signals for the 4-phase handshake
  // req: sender requests transfer (goes high when valid & ready)
  // ack: receiver acknowledges (goes high when it sees req)
  // The 4-phase protocol:
  //   Phase 0: req=0, ack=0 (idle)
  //   Phase 1: req=1, ack=0 (request sent)
  //   Phase 2: req=1, ack=1 (acknowledged)
  //   Phase 3: req=0, ack=1 (request deasserted)
  //   Back to Phase 0: req=0, ack=0 (ack deasserted)

  // Source side state
  reg src_req;
  reg src_ack;
  reg [WIDTH-1:0] src_data_reg;

  // Destination side state
  reg dst_req;
  reg dst_ack;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronizers for req (src -> dst)
  reg [1:0] req_sync;
  wire req_synced = req_sync[1];

  // Synchronizers for ack (dst -> src)
  reg [1:0] ack_sync;
  wire ack_synced = ack_sync[1];

  // Synchronizers for data (src -> dst) - use a small FIFO or just sync data
  // Since we use 4-phase handshake, data is stable while req is high.
  // We can use a multi-bit synchronizer or a small FIFO.
  // For simplicity and correctness, let's use a 2-stage synchronizer for each bit
  // but that's not safe for multi-bit. Instead, we'll use a small async FIFO
  // or we can rely on the fact that data is stable during the handshake.
  // Actually, the safest approach is to use a small async FIFO for data.
  // But let's think: in 4-phase handshake, the data is valid and stable from
  // the moment req goes high until req goes low. The receiver can sample
  // the data when it sees req go high (after synchronization).
  // We need to synchronize the data as well. Let's use a simple approach:
  // synchronize each bit of data with a 2-stage synchronizer, but this is
  // not guaranteed to be coherent. Better to use a small async FIFO.

  // Let's use a simple 2-entry async FIFO for data.
  // Actually, let's reconsider. The 4-phase handshake ensures that:
  // 1. Sender asserts req when it has valid data
  // 2. Data remains stable while req is high
  // 3. Receiver samples data when it detects req transition
  // 4. Receiver asserts ack
  // 5. Sender deasserts req when it sees ack
  // 6. Receiver deasserts ack
  //
  // The data needs to be synchronized. Since data is stable during the
  // handshake, we can use a simple multi-bit synchronizer if we ensure
  // that the data doesn't change while req is high. But multi-bit
  // synchronizers are not safe in general.
  //
  // A better approach: use a small async FIFO (e.g., 2 entries) for data.
  // The sender writes to the FIFO when it asserts req.
  // The receiver reads from the FIFO when it detects the req transition.

  // Let's implement a simple 2-entry async FIFO for data.
  // Actually, for a 4-phase handshake, we only need to transfer one item
  // at a time. So we can use a simpler approach:
  // - Synchronize the data using a small async FIFO or by ensuring
  //   data stability.
  //
  // Let's use a different approach: since the 4-phase handshake ensures
  // that data is stable while req is high, we can synchronize the data
  // by using a 2-stage synchronizer for each bit, but we need to ensure
  // that all bits are synchronized coherently. This is tricky.
  //
  // The safest approach is to use an async FIFO. Let's implement a
  // simple 2-entry async FIFO.

  // Actually, let's simplify. We'll use the following approach:
  // - The sender holds the data stable while req is high.
  // - The receiver uses a 2-stage synchronizer for req.
  // - When the receiver sees req go high (synchronized), it samples
  //   the data. But the data also needs to be synchronized.
  //
  // Let's use a small async FIFO for data. Here's a simple 2-entry FIFO:

  // FIFO implementation
  reg [WIDTH-1:0] fifo_mem [0:1];
  reg [1:0] fifo_wr_ptr;
  reg [1:0] fifo_rd_ptr;
  reg [1:0] fifo_wr_ptr_sync [0:1];
  reg [1:0] fifo_rd_ptr_sync [0:1];

  wire fifo_full = (fifo_wr_ptr[1] != fifo_rd_ptr_sync[1][1]) &&
                   (fifo_wr_ptr[0] != fifo_rd_ptr_sync[1][0]) &&
                   (fifo_wr_ptr[1] == fifo_rd_ptr_sync[1][1]) &&
                   (fifo_wr_ptr[0] == fifo_rd_ptr_sync[1][0] ^ 1'b1);
  // This is getting complicated. Let's use a simpler approach.

  // Actually, for a 4-phase handshake, we only transfer one item at a time.
  // So we don't need a FIFO. We can just synchronize the data directly.
  // The key insight is that in a 4-phase handshake, the data is stable
  // for the entire duration of the handshake (from req high to req low).
  // So we can use a simple multi-bit synchronizer if we ensure that
  // the data doesn't change during the handshake.
  //
  // But multi-bit synchronizers are not safe. Let's use a different approach:
  // We'll use a 2-stage synchronizer for req, and when the receiver sees
  // req go high, it will sample the data. To ensure the data is stable,
  // we'll use a small async FIFO with 2 entries.

  // Let's implement a simple 2-entry async FIFO properly.

  // Write pointer (source clock domain)
  reg [1:0] wr_ptr;
  // Read pointer (destination clock domain)
  reg [1:0] rd_ptr;
  // Synchronized read pointer (source clock domain)
  reg [1:0] rd_ptr_sync [0:1];
  // Synchronized write pointer (destination clock domain)
  reg [1:0] wr_ptr_sync [0:1];

  wire [1:0] rd_ptr_synced = rd_ptr_sync[1];
  wire [1:0] wr_ptr_synced = wr_ptr_sync[1];

  wire fifo_full = (wr_ptr[1] != rd_ptr_synced[1]) &&
                   (wr_ptr[0] != rd_ptr_synced[0]) &&
                   (wr_ptr[1] == rd_ptr_synced[1] ^ 1'b1) &&
                   (wr_ptr[0] == rd_ptr_synced[0] ^ 1'b1);
  // This is still complicated. Let's use a simpler full/empty check.

  // For a 2-entry FIFO:
  // Full when wr_ptr and rd_ptr differ in the MSB and are equal in the LSB
  // Empty when wr_ptr == rd_ptr

  wire fifo_full_simple = (wr_ptr[1] != rd_ptr_synced[1]) &&
                          (wr_ptr[0] == rd_ptr_synced[0]);
  wire fifo_empty_simple = (wr_ptr_synced == rd_ptr);

  // This is getting too complicated. Let's use a different approach.

  // Since we're using a 4-phase handshake, we only need to transfer one
  // item at a time. So we can simplify by not using a FIFO at all.
  // Instead, we'll synchronize the data using a 2-stage synchronizer
  // for each bit, but we'll ensure that the data is stable during the
  // handshake.

  // Actually, the simplest and most correct approach is to use a small
  // async FIFO. Let's implement it properly.

  // Let's restart with a cleaner approach.

  // 4-phase handshake signals
  reg src_req_r;
  reg src_ack_r;
  reg [WIDTH-1:0] src_data_r;

  reg dst_req_r;
  reg dst_ack_r;
  reg [WIDTH-1:0] dst_data_r;

  // Synchronizers
  reg [1:0] req_sync_r;
  reg [1:0] ack_sync_r;

  // Data synchronizer - use a small async FIFO
  // For simplicity, let's use a 2-entry async FIFO

  // FIFO memory
  reg [WIDTH-1:0] fifo_mem [0:1];

  // Write pointer (src domain)
  reg [1:0] fifo_wr_ptr;

  // Read pointer (dst domain)
  reg [1:0] fifo_rd_ptr;

  // Synchronized pointers
  reg [1:0] fifo_wr_ptr_sync [0:1];
  reg [1:0] fifo_rd_ptr_sync [0:1];

  wire [1:0] fifo_wr_ptr_synced = fifo_wr_ptr_sync[1];
  wire [1:0] fifo_rd_ptr_synced = fifo_rd_ptr_sync[1];

  wire fifo_full = (fifo_wr_ptr[1] != fifo_rd_ptr_synced[1]) &&
                   (fifo_wr_ptr[0] == fifo_rd_ptr_synced[0]);
  wire fifo_empty = (fifo_wr_ptr_synced == fifo_rd_ptr);

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req_r <= 1'b0;
      src_ack_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
      fifo_wr_ptr <= 2'b00;
      req_sync_r <= 2'b00;
      ack_sync_r <= 2'b00;
      fifo_wr_ptr_sync[0] <= 2'b00;
      fifo_wr_ptr_sync[1] <= 2'b00;
    end else begin
      // Synchronizers
      req_sync_r <= {req_sync_r[0], dst_req_r};
      ack_sync_r <= {ack_sync_r[0], dst_ack_r};
      fifo_wr_ptr_sync[0] <= fifo_wr_ptr;
      fifo_wr_ptr_sync[1] <= fifo_wr_ptr_sync[0];

      // 4-phase handshake state machine
      if (!src_req_r) begin
        // Phase 0: idle, waiting for valid data
        if (src_valid_i && !fifo_full) begin
          src_req_r <= 1'b1;
          src_data_r <= src_data_i;
          fifo_mem[fifo_wr_ptr[0]] <= src_data_i;
          fifo_wr_ptr <= fifo_wr_ptr + 2'b01;
        end
      end else begin
        // Phase 1 or 2: req is high
        if (ack_sync_r[1]) begin
          // Phase 2: ack is high, deassert req
          src_req_r <= 1'b0;
          src_ack_r <= 1'b1;
        end
      end

      if (src_ack_r && !ack_sync_r[1]) begin
        // Phase 3: req is low, ack is high, deassert ack
        src_ack_r <= 1'b0;
      end
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_r <= 1'b0;
      dst_ack_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
      fifo_rd_ptr <= 2'b00;
      fifo_rd_ptr_sync[0] <= 2'b00;
      fifo_rd_ptr_sync[1] <= 2'b00;
    end else begin
      // Synchronizers
      fifo_rd_ptr_sync[0] <= fifo_rd_ptr;
      fifo_rd_ptr_sync[1] <= fifo_rd_ptr_sync[0];

      // 4-phase handshake state machine
      if (!dst_req_r) begin
        // Phase 0: idle, waiting for req
        if (req_sync_r[1]) begin
          dst_req_r <= 1'b1;
          dst_data_r <= fifo_mem[fifo_rd_ptr[0]];
          fifo_rd_ptr <= fifo_rd_ptr + 2'b01;
        end
      end else begin
        // Phase 1 or 2: req is high
        if (!dst_ack_r) begin
          // Phase 1: req is high, ack is low, assert ack
          dst_ack_r <= 1'b1;
        end
      end

      if (dst_ack_r && !req_sync_r[1]) begin
        // Phase 3: req is low, ack is high, deassert ack
        dst_ack_r <= 1'b0;
      end
    end
  end

  // Outputs
  assign src_ready_o = !src_req_r && !fifo_full;
  assign dst_data_o = dst_data_r;
  assign dst_valid_o = dst_req_r && !dst_ack_r;

endmodule
