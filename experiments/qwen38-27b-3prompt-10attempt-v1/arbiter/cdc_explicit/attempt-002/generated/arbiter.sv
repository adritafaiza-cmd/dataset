module arbiter #
(
    parameter PORTS = 4,
    parameter ARB_TYPE_ROUND_ROBIN = 0,
    parameter ARB_BLOCK = 0,
    parameter ARB_BLOCK_ACK = 1,
    parameter ARB_LSB_HIGH_PRIORITY = 0
)
(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [PORTS-1:0]         request,
    input  wire [PORTS-1:0]         acknowledge,
    output wire [PORTS-1:0]         grant,
    output wire                     grant_valid,
    output wire [$clog2(PORTS)-1:0] grant_encoded
);

    localparam ENC_WIDTH = $clog2(PORTS);

    // Internal signals
    wire [PORTS-1:0] grant_comb;
    wire             grant_valid_comb;
    wire [ENC_WIDTH-1:0] grant_encoded_comb;

    // State for round-robin and blocking
    reg [PORTS-1:0] rr_mask;
    reg [PORTS-1:0] blocked_grant;
    reg             blocked_valid;

    // Combinational logic for grant calculation
    // First, determine the effective request based on blocking mode
    wire [PORTS-1:0] effective_request;

    generate
        if (ARB_BLOCK) begin
            // When blocking is enabled, if we have a blocked grant, 
            // we hold it until acknowledge or request drops
            assign effective_request = blocked_valid ? blocked_grant : request;
        end else begin
            assign effective_request = request;
        end
    endgenerate

    // Priority encoder logic
    // We need to handle round-robin vs fixed priority
    // And LSB high vs MSB high priority

    // For round-robin, we rotate the request based on rr_mask
    // rr_mask indicates which ports have lower priority (already served)
    // Actually, let's use a different approach: 
    // In round-robin, we want to give priority to the port after the last granted port.
    // We can do this by rotating the request vector.

    // Let's define the priority order
    // If ARB_LSB_HIGH_PRIORITY is 1, LSB has highest priority
    // If ARB_LSB_HIGH_PRIORITY is 0, MSB has highest priority

    // For fixed priority:
    //   If LSB high: priority order is 0, 1, 2, ..., PORTS-1
    //   If MSB high: priority order is PORTS-1, PORTS-2, ..., 0

    // For round-robin:
    //   We rotate the priority based on the last granted port

    // Let's implement a priority encoder that can handle both cases

    // Step 1: Determine the candidate set
    // For round-robin, we need to rotate the request
    // Let's use a simpler approach: 
    //   Create a rotated version of the request where the "start" of priority is shifted

    // Actually, let's use a standard approach:
    //   For round-robin, we maintain a pointer to the next port to serve
    //   We rotate the request vector so that the next port is at position 0
    //   Then apply fixed priority (LSB or MSB high)

    // Let's define the rotation
    // If last granted port was i, then next priority starts at i+1
    // We rotate request left by (i+1) positions

    // But we need to know the last granted port. Let's use rr_mask differently.
    // rr_mask[i] = 1 means port i has been served since last reset or since last full cycle
    // Actually, let's use a simpler round-robin: 
    //   We keep track of the last granted port index
    //   Then we rotate the request so that the port after last granted is at LSB

    // Let's use a register to store the last granted port
    reg [ENC_WIDTH-1:0] last_grant_idx;

    // For round-robin, we rotate the request
    // Rotation amount = last_grant_idx + 1
    // But we need to handle the case where no port has been granted yet

    // Let's use a different approach for round-robin:
    //   We create a rotated request where the priority starts from the port after last_grant_idx
    //   Then we apply fixed priority to the rotated request

    // Generate rotated request
    wire [PORTS-1:0] rotated_request;
    wire [ENC_WIDTH-1:0] rotate_amount;

    assign rotate_amount = (ARB_TYPE_ROUND_ROBIN) ? (last_grant_idx + 1) : 0;

    // Rotate left by rotate_amount
    // We can do this with a mux tree or a shift
    // For simplicity, let's use a case statement or a shift register approach

    // Actually, let's use a simpler method:
    //   For each bit position i in the rotated request, 
    //   rotated_request[i] = request[(i + rotate_amount) % PORTS]

    genvar i;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : gen_rotate
            assign rotated_request[i] = request[(i + rotate_amount) % PORTS];
        end
    endgenerate

    // Now apply fixed priority to rotated_request
    // If ARB_LSB_HIGH_PRIORITY is 1, LSB of rotated_request has highest priority
    // If ARB_LSB_HIGH_PRIORITY is 0, MSB of rotated_request has highest priority

    // Priority encoder for rotated_request
    // We need to find the highest priority bit that is set

    // For LSB high priority: find the lowest set bit
    // For MSB high priority: find the highest set bit

    wire [PORTS-1:0] priority_grant_rotated;
    wire             priority_grant_valid_rotated;

    generate
        if (ARB_LSB_HIGH_PRIORITY) begin
            // LSB has highest priority: find lowest set bit
            // This is equivalent to: grant = request & (~request + 1)
            // But we need to handle the case where no bit is set
            assign priority_grant_rotated = rotated_request & (~rotated_request + 1'b1);
            assign priority_grant_valid_rotated = |rotated_request;
        end else begin
            // MSB has highest priority: find highest set bit
            // We can do this by masking from MSB down
            // Let's use a priority encoder
            reg [PORTS-1:0] msb_grant;
            integer j;
            always @* begin
                msb_grant = {PORTS{1'b0}};
                for (j = PORTS-1; j >= 0; j = j - 1) begin
                    if (rotated_request[j]) begin
                        msb_grant = {PORTS{1'b0}};
                        msb_grant[j] = 1'b1;
                    end
                end
            end
            assign priority_grant_rotated = msb_grant;
            assign priority_grant_valid_rotated = |rotated_request;
        end
    endgenerate

    // Now we need to un-rotate the grant to get the actual port
    // If rotated_request[i] corresponds to original request[(i + rotate_amount) % PORTS]
    // Then if priority_grant_rotated[i] is set, the actual port is (i + rotate_amount) % PORTS

    wire [PORTS-1:0] grant_unrotated;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : gen_unrotate
            assign grant_unrotated[(i + rotate_amount) % PORTS] = priority_grant_rotated[i];
        end
    endgenerate

    // Now handle blocking
    // If ARB_BLOCK is set, we hold the grant until acknowledge or request drops

    // Combinational grant
    assign grant_comb = (ARB_BLOCK && blocked_valid) ? blocked_grant : grant_unrotated;
    assign grant_valid_comb = (ARB_BLOCK && blocked_valid) ? 1'b1 : priority_grant_valid_rotated;

    // Encode the grant
    // We need to encode grant_comb to grant_encoded_comb
    // Use a priority encoder on grant_comb

    reg [ENC_WIDTH-1:0] encoded_tmp;
    integer k;
    always @* begin
        encoded_tmp = {ENC_WIDTH{1'b0}};
        for (k = 0; k < PORTS; k = k + 1) begin
            if (grant_comb[k]) begin
                encoded_tmp = k[ENC_WIDTH-1:0];
            end
        end
    end
    assign grant_encoded_comb = encoded_tmp;

    // Sequential logic for blocking and round-robin state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_mask <= {PORTS{1'b0}};
            blocked_grant <= {PORTS{1'b0}};
            blocked_valid <= 1'b0;
            last_grant_idx <= {ENC_WIDTH{1'b0}};
        end else begin
            // Update last_grant_idx for round-robin
            if (grant_valid_comb) begin
                last_grant_idx <= grant_encoded_comb;
            end

            // Update blocking state
            if (ARB_BLOCK) begin
                if (grant_valid_comb) begin
                    // A grant is being issued
                    if (ARB_BLOCK_ACK) begin
                        // Hold until acknowledge
                        if (|acknowledge) begin
                            // Acknowledge received, release the block
                            blocked_valid <= 1'b0;
                            blocked_grant <= {PORTS{1'b0}};
                        end else begin
                            // No acknowledge, hold the grant
                            blocked_valid <= 1'b1;
                            blocked_grant <= grant_comb;
                        end
                    end else begin
                        // Hold until request drops
                        if (grant_comb[grant_encoded_comb] == 1'b0) begin
                            // Request dropped, release the block
                            blocked_valid <= 1'b0;
                            blocked_grant <= {PORTS{1'b0}};
                        end else begin
                            // Request still active, hold the grant
                            blocked_valid <= 1'b1;
                            blocked_grant <= grant_comb;
                        end
                    end
                end else begin
                    // No grant, clear blocking state
                    blocked_valid <= 1'b0;
                    blocked_grant <= {PORTS{1'b0}};
                end
            end else begin
                // No blocking, clear state
                blocked_valid <= 1'b0;
                blocked_grant <= {PORTS{1'b0}};
            end
        end
    end

    // Assign outputs
    assign grant = grant_comb;
    assign grant_valid = grant_valid_comb;
    assign grant_encoded = grant_encoded_comb;

endmodule
