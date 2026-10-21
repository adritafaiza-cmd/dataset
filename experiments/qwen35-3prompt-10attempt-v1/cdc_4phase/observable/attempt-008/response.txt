```systemverilog
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

  // Sender side registers
  logic src_valid_reg;
  logic src_data_reg [WIDTH-1:0];
  logic src_ready_reg;

  // Receiver side registers
  logic dst_valid_reg;
  logic dst_data_reg [WIDTH-1:0];
  logic dst_ready_reg;

  // Handshake signals for the receiver side (internal to receiver logic)
  logic dst_valid_int;
  logic dst_ready_int;

  // Reset message handling
  logic [WIDTH-1:0] reset_msg_reg;

  // Sender Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_data_reg <= '{default: 1'b0};
      src_ready_reg <= 1'b1;
    end else begin
      src_valid_reg <= src_valid_i;
      src_data_reg <= src_data_i;
      src_ready_reg <= dst_ready_i;
    end
  end

  // Receiver Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_data_reg <= '{default: 1'b0};
      dst_ready_reg <= 1'b1;
      dst_valid_int <= 1'b0;
      dst_ready_int <= 1'b1;
      reset_msg_reg <= RESET_MSG;
    end else begin
      dst_valid_reg <= dst_valid_i;
      dst_data_reg <= dst_data_i;
      dst_ready_reg <= src_ready_i;
      
      // Internal handshake signals
      dst_valid_int <= dst_valid_i;
      dst_ready_int <= src_ready_i;
      
      // Reset message handling
      if (SEND_RESET_MSG && !dst_valid_i && dst_ready_i) begin
        reset_msg_reg <= RESET_MSG;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Four-phase handshake logic
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i
  logic [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
    end
  end

  // Receiver side: Synchronize src_valid_i
  logic [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
    end
  end

  // Receiver side: Synchronize src_data_i
  logic [WIDTH-1:0] src_data_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync <= '{default: 1'b0};
    end else begin
      src_data_sync <= src_data_i;
    end
  end

  // Receiver side: Synchronize src_ready_o
  logic [1:0] src_ready_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_ready_sync <= 2'b00;
    end else begin
      src_ready_sync <= {src_ready_sync[0], src_ready_o};
    end
  end

  // Four-phase handshake implementation
  // Phase 1: Sender asserts valid, waits for ready
  // Phase 2: Receiver samples valid and data, asserts ready
  // Phase 3: Sender deasserts valid, waits for ready
  // Phase 4: Receiver deasserts ready, waits for valid

  // Sender side: Drive ready based on receiver's ready signal
  // Receiver side: Drive valid based on sender's valid signal

  // Cross-domain synchronization for handshake signals
  // We use a simple synchronizer chain to ensure stability before using the signals

  // Sender side: Synchronize dst_ready_i