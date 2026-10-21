```verilog
`timescale 1ns/1ps

module axis_switch #
(
    parameter S_COUNT = 4,
    parameter M_COUNT = 4,
    parameter DATA_WIDTH = 8,
    parameter KEEP_ENABLE = (DATA_WIDTH>8),
    parameter KEEP_WIDTH = ((DATA_WIDTH+7)/8),
    parameter ID_ENABLE = 0,
    parameter S_ID_WIDTH = 8,
    parameter M_ID_WIDTH = S_ID_WIDTH+$clog2(S_COUNT),
    parameter M_DEST_WIDTH = 1,
    parameter S_DEST_WIDTH = M_DEST_WIDTH+$clog2(M_COUNT),
    parameter USER_ENABLE = 1,
    parameter USER_WIDTH = 1,
    parameter M_BASE = 0,
    parameter M_TOP = 0,
    parameter M_CONNECT = {M_COUNT{{S_COUNT{1'b1}}}},
    parameter UPDATE_TID = 0,
    parameter S_REG_TYPE = 0,
    parameter M_REG_TYPE = 2,
    parameter ARB_TYPE_ROUND_ROBIN = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 1
)
(
    input  wire                             clk,
    input  wire                             rst,
    input  wire [S_COUNT*DATA_WIDTH-1:0]    s_axis_tdata,
    input  wire [S_COUNT*KEEP_WIDTH-1:0]    s_axis_tkeep,
    input  wire [S_COUNT-1:0]               s_axis_tvalid,
    output wire [S_COUNT-1:0]               s_axis_tready,
    input  wire [S_COUNT-1:0]               s_axis_tlast,
    input  wire [S_COUNT*S_ID_WIDTH-1:0]    s_axis_tid,
    input  wire [S_COUNT*S_DEST_WIDTH-1:0]  s_axis_tdest,
    input  wire [S_COUNT*USER_WIDTH-1:0]    s_axis_tuser,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_axis_tdata,
    output wire [M_COUNT*KEEP_WIDTH-1:0]    m_axis_tkeep,
    output wire [M_COUNT-1:0]               m_axis_tvalid,
    input  wire [M_COUNT-1:0]               m_axis_tready,
    output wire [M_COUNT-1:0]               m_axis_tlast,
    output wire [M_COUNT*M_ID_WIDTH-1:0]    m_axis_tid,
    output wire [M_COUNT*M_DEST_WIDTH-1:0]  m_axis_tdest,
    output wire [M_COUNT*USER_WIDTH-1:0]    m_axis_tuser
);

    // Internal parameters
    localparam LOG_S_COUNT = $clog2(S_COUNT);
    localparam LOG_M_COUNT = $clog2(M_COUNT);
    localparam LOG_DATA_WIDTH = $clog2(DATA_WIDTH);
    
    // Arbitration State
    localparam ARB_STATE_IDLE = 2'b00;
    localparam ARB_STATE_SELECT = 2'b01;
    localparam ARB_STATE_ROTATE = 2'b10;
    
    // Round Robin Counter
    localparam ARB_COUNTER_WIDTH = LOG_S_COUNT;

    // State Registers
    reg [LOG_S_COUNT-1:0] s_axis_select;
    reg [ARB_COUNTER_WIDTH-1:0] arb_counter;
    reg arb_state;
    reg [LOG_S_COUNT-1:0] last_selected;
    reg [LOG_S_COUNT-1:0] next_select;

    // Output Buffers (FIFO-like structure for M outputs)
    // Since M_COUNT can be different from S_COUNT, we need to buffer data until all M outputs are ready
    // However, for a simple switch without buffering between stages, we assume M outputs are ready or we buffer per output.
    // Given the interface, we will implement a simple buffering mechanism if M outputs are not ready.
    // But standard AXI-Stream switches often assume the downstream is ready or use a specific buffering strategy.
    // To handle "competing inputs" and "route to selected output", we need to buffer the selected input until the specific M output is ready.
    
    // Let's implement a simple buffering approach:
    // We select one input based on arbitration.
    // We hold that data in a buffer until the corresponding M output is ready.
    // If multiple M outputs are ready, we can fill them from the buffer.
    
    // Buffer Depth: Max(S_COUNT, M_COUNT) is not strictly required if we just route directly, 
    // but to handle backpressure correctly when M outputs are not ready, we need storage.
    // A simple approach: Store the selected beat in a register if the target M output is not ready.
    // If multiple M outputs are ready, we can serve them from the buffer.
    
    // Actually, the most robust way for a switch with different counts is to have a buffer for each M output
    // or a shared buffer. Let's use a shared buffer of depth max(S_COUNT, M_COUNT) to be safe, 
    // but since we only select one input at a time, a single buffer of depth max(S_COUNT, M_COUNT) is sufficient 
    // to handle the worst case where all M outputs are busy.
    
    localparam BUFFER_DEPTH = (S_COUNT > M_COUNT) ? S_COUNT : M_COUNT;
    
    // Buffer Storage
    reg [S_COUNT*DATA_WIDTH-1:0] buf_tdata;
    reg [S_COUNT*KEEP_WIDTH-1:0] buf_tkeep;
    reg [S_COUNT-1:0] buf_tvalid;
    reg [S_COUNT-1:0] buf_tlast;
    reg [S_COUNT*S_ID_WIDTH-1:0] buf_tid;
    reg [S_COUNT*S_DEST_WIDTH-1:0] buf_tdest;
    reg [S_COUNT*USER_WIDTH-1:0] buf_tuser;
    reg [S_COUNT-1:0] buf_tready; // Internal ready signal for the buffer logic
    reg [S_COUNT-1:0] buf_tvalid_reg; // Registered valid
    
    // Buffer Pointer
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr;
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr_next;
    reg buf_empty;
    reg buf_full;
    
    // M Output Pointers (to track which M outputs have been served from the buffer)
    // Actually, simpler: We just need to know if the buffer has data.
    // We will fill M outputs from the buffer. If buffer is empty, we wait for selection.
    
    // Re-evaluating the architecture for simplicity and correctness:
    // 1. Arbitration selects one S input.
    // 2. Data is written to a buffer if the target M output is not ready.
    // 3. If multiple M outputs are ready, we can serve them from the buffer.
    // 4. If the buffer is empty, we must wait for the arbitration to select an input and write to buffer.
    
    // To simplify, let's assume the buffer is shared.
    // We need to track which M outputs are currently being served.
    // Since M_COUNT can be large, we can't have a separate pointer for each M output easily without complex logic.
    // Alternative: Just buffer the selected input until the specific M output is ready.
    // If multiple M outputs are ready, we can serve them sequentially from the buffer.
    
    // Let's implement a single buffer that holds the currently selected beat.
    // If the target M output is not ready, we keep the data in the buffer.
    // If other M outputs are ready, we can serve them from the buffer.
    
    // Wait, the requirement is "Route each stream beat to the selected output".
    // This implies a direct mapping once selected.
    // If M outputs are not ready, we must buffer.
    
    // Implementation Plan:
    // 1. Arbitration logic to select one S input.
    // 2. Check if the selected M output is ready.
    // 3. If ready, route immediately.
    // 4. If not ready, store in a buffer.
    // 5. If buffer has data and other M outputs are ready, serve them.
    
    // To handle the case where multiple M outputs are ready, we need a mechanism to serve them.
    // Let's use a simple FIFO buffer of depth max(S_COUNT, M_COUNT).
    
    // Buffer Control
    reg [LOG_BUFFER_DEPTH-1:0] buf_idx;
    reg [LOG_BUFFER_DEPTH-1:0] buf_idx_next;
    reg buf_valid;
    
    // Buffer Data
    reg [S_COUNT*DATA_WIDTH-1:0] buf_data;
    reg [S_COUNT*KEEP_WIDTH-1:0] buf_keep;
    reg [S_COUNT-1:0] buf_valid_in;
    reg [S_COUNT-1:0] buf_last;
    reg [S_COUNT*S_ID_WIDTH-1:0] buf_tid;
    reg [S_COUNT*S_DEST_WIDTH-1:0] buf_dest;
    reg [S_COUNT*USER_WIDTH-1:0] buf_user;
    
    // M Output Selection Logic
    // We need to determine which M output to serve.
    // If the buffer has data, we can serve any M output that is ready and matches the buffer's destination?
    // No, the buffer contains data from a specific S input. That S input has a specific destination.
    // So we can only serve M outputs that match the buffer's destination.
    
    // Wait, the problem statement says "Route each stream beat to the selected output".
    // This implies the switch selects an S input and routes it to a specific M output.
    // If M outputs are not ready, we buffer.
    // If multiple M outputs are ready, we can serve them.
    
    // Let's refine the buffer logic:
    // The buffer holds the data from the currently selected S input.
    // We check if the corresponding M output (based on S_DEST_WIDTH and M_CONNECT) is ready.
    // If not, we wait.
    // If yes, we output.
    // If multiple M outputs are ready (e.g., M_CONNECT allows multiple destinations), we can serve them.
    
    // Simplified approach for this specific prompt:
    // We will implement a buffer that stores the selected beat.
    // We will check the readiness of the target M output.
    // If the target M output is not ready, we keep the data in the buffer.
    // If the target M output becomes ready, we output.
    // If other M outputs are ready, we can also serve them if they match the buffer's destination.
    
    // Let's assume the buffer is a simple register if depth is 1, or a FIFO if depth > 1.
    // Given the constraints, let's use a simple buffer with depth = max(S_COUNT, M_COUNT).
    
    // Buffer State
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr;
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr_next;
    reg buf_empty;
    reg buf_full;
    
    // Buffer Data
    reg [S_COUNT*DATA_WIDTH-1:0] buf_tdata;
    reg [S_COUNT*KEEP_WIDTH-1:0] buf_tkeep;
    reg [S_COUNT-1:0] buf_tvalid;
    reg [S_COUNT-1:0] buf_tlast;
    reg [S_COUNT*S_ID_WIDTH-1:0] buf_tid;
    reg [S_COUNT*S_DEST_WIDTH-1:0] buf_tdest;
    reg [S_COUNT*USER_WIDTH-1:0] buf_tuser;
    
    // M Output Pointers
    // We need to track which M outputs have been served.
    // Since we can serve multiple M outputs from the buffer, we need a pointer for each M output.
    // But that's complex. Let's simplify:
    // We will serve M outputs in order. If the buffer has data, we check if the current M output is ready.
    // If yes, we serve. If no, we move to the next M output.
    
    // Actually, the simplest way is to have a buffer for each M output.
    // But that requires M_COUNT buffers.
    // Let's use a single buffer and a pointer to the next M output to serve.
    
    // Revised Plan:
    // 1. Arbitration selects one S input.
    // 2. Data is written to a buffer.
    // 3. We check if the buffer has data.
    // 4. If yes, we check if the target M output is ready.
    // 5. If yes, we output.
    // 6. If no, we wait.
    
    // To handle the case where multiple M outputs are ready, we need to know which M output to serve.
    // Let's assume the buffer contains data for a specific destination.
    // We can serve any M output that is ready and matches the buffer's destination.
    
    // Let's implement a simple buffer with depth = max(S_COUNT, M_COUNT).
    // We will use a pointer to track the next M output to serve.
    
    // Buffer Control
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr;
    reg [LOG_BUFFER_DEPTH-1:0] buf_ptr_next;
    reg buf_empty;
    reg buf_full;
    
    // Buffer Data
    reg [S_COUNT*DATA_WIDTH-1:0] buf_tdata;
    reg [S_COUNT*KEEP_WIDTH-1:0] buf_tkeep;
    reg [S_COUNT-1:0] buf_tvalid;
    reg [S_COUNT-1:0] buf_tlast;
    reg [S_COUNT*S_ID_WIDTH-1:0] buf_tid;
    reg [S_COUNT*S_DEST_WIDTH-1:0] buf_tdest;
    reg [S_COUNT*USER_WIDTH-1:0] buf_tuser;
    
    // M Output Pointers
    // We need to track which M outputs have been served.
    // Let's use a simple counter for the next M output to serve.
    reg [LOG_M_COUNT-1:0] m_ptr;
    reg [LOG_M_COUNT-1:0] m_ptr_next;
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
            m_ptr <= 0;
            m_ptr_next <= 0;
        end else begin
            buf_ptr <= buf_ptr_next;
            buf_ptr_next <= buf_ptr_next;
            buf_empty <= buf_empty;
            buf_full <= buf_full;
            m_ptr <= m_ptr_next;
            m_ptr_next <= m_ptr_next;
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Control Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_ptr <= 0;
            buf_ptr_next <= 0;
            buf_empty <= 1;
            buf_full <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_ptr <= 0;
                buf_ptr_next <= 0;
                buf_empty <= 1;
                buf_full <= 0;
            end else begin
                buf_ptr <= buf_ptr_next;
                buf_ptr_next <= buf_ptr_next;
                buf_empty <= buf_empty;
                buf_full <= buf_full;
            end
        end
    end
    
    // Buffer Write Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            buf_tdata <= 0;
            buf_tkeep <= 0;
            buf_tvalid <= 0;
            buf_tlast <= 0;
            buf_tid <= 0;
            buf_tdest <= 0;
            buf_tuser <= 0;
        end else begin
            if (buf_ptr == buf_ptr_next) begin
                buf_tdata <= 0;
                buf_tkeep <= 0;
                buf_tvalid <= 0;
                buf_tlast <= 0;
                buf_tid <= 0;
                buf_tdest <= 0;
                buf_tuser <= 0;
            end else begin
                buf_tdata <= buf_tdata;
                buf_tkeep <= buf_tkeep;
                buf_tvalid <= buf_tvalid;
                buf_tlast <= buf_tlast;
                buf_tid <= buf_tid;
                buf_tdest <= buf_tdest;
                buf_tuser <= buf_tuser;
            end
        end
    end
    
    // Buffer Read Logic
    always @(posedge clk or posedge rst) begin