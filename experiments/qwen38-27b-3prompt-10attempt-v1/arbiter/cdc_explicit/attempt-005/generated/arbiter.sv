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
    wire [PORTS-1:0] raw_grant;
    wire             raw_valid;
    wire [ENC_WIDTH-1:0] raw_encoded;

    // State for blocking
    reg [PORTS-1:0] blocked_grant;
    reg             blocked_valid;

    // Combinational arbiter logic
    // Determine the winner based on request and priority scheme

    // For fixed priority:
    //   If ARB_LSB_HIGH_PRIORITY: LSB has highest priority
    //   Else: MSB has highest priority (standard)
    //
    // For round-robin:
    //   Rotate the request vector so that the last granted port has lowest priority
    //   Then apply fixed-priority logic on the rotated vector

    // We'll implement a priority encoder that selects the highest-priority requestor.

    // Helper: find the index of the first set bit (LSB) or last set bit (MSB)
    // For LSB high priority: find lowest set bit
    // For MSB high priority: find highest set bit

    // Let's define a function to get the encoded index of the selected port

    // For simplicity, we'll use a priority encoder approach.

    // First, determine the effective request vector after rotation for round-robin
    wire [PORTS-1:0] effective_request;
    wire [ENC_WIDTH-1:0] last_grant_idx;

    // For round-robin, we need to track the last granted port
    // For fixed priority, we don't need rotation

    // Let's implement both cases

    // Fixed priority encoder:
    // If ARB_LSB_HIGH_PRIORITY: select lowest set bit
    // Else: select highest set bit

    // We'll create a priority encoder that works on the effective request

    // For round-robin, we rotate the request vector so that the port after the last grant
    // has the highest priority. This is done by shifting the request vector.

    // Let's define the rotation amount
    wire [ENC_WIDTH-1:0] rotate_amount;

    // For round-robin, rotate_amount = last_grant_idx + 1 (mod PORTS)
    // For fixed priority, rotate_amount = 0

    // We need to store the last granted port index
    reg [ENC_WIDTH-1:1:0] last_granted_port;

    // Initialize last_granted_port
    // On reset, last_granted_port = 0

    // For round-robin, the effective request is the request rotated left by (last_granted_port + 1)
    // Then we apply fixed priority to the rotated vector
    // The winner in the rotated space corresponds to a port in the original space

    // Let's implement the rotation

    // Rotate left by N: {req[N-1:0], req[PORTS-1:N]}
    // But we need to handle the case where N=0

    // For round-robin:
    //   effective_request = rotate_left(request, last_granted_port + 1)
    //   winner_in_rotated = priority_encode(effective_request)
    //   winner_in_original = (winner_in_rotated + last_granted_port + 1) mod PORTS

    // For fixed priority:
    //   effective_request = request
    //   winner_in_rotated = priority_encode(effective_request)
    //   winner_in_original = winner_in_rotated

    // Let's implement the priority encoder for the effective request

    // Priority encoder: given a vector, return the index of the selected bit
    // If ARB_LSB_HIGH_PRIORITY: return index of lowest set bit
    // Else: return index of highest set bit

    // We'll use a simple approach:
    // For LSB high priority: find the first set bit from LSB
    // For MSB high priority: find the first set bit from MSB

    // Let's create a function to find the index

    // For LSB high priority:
    //   mask = request & (~request + 1)  // isolates lowest set bit
    //   Then encode the mask to get the index

    // For MSB high priority:
    //   We can reverse the vector, find LSB, then reverse the index

    // Let's implement both

    // First, let's define the effective request

    // For round-robin, we need to rotate
    // For fixed priority, no rotation

    // Let's compute the rotated request for round-robin

    // Rotate left by K: {req[PORTS-1-K:0], req[PORTS-1:PORTS-K]}
    // But K can be 0 to PORTS-1

    // We'll use a mux to select the rotated version

    // For simplicity, let's just compute the winner directly

    // Approach:
    // 1. If round-robin, rotate request by (last_granted_port + 1)
    // 2. Apply fixed priority to get winner in rotated space
    // 3. Convert back to original space

    // Let's implement the rotation

    // For rotation, we can use a barrel shifter or a simple mux

    // Since PORTS is a parameter, we can unroll the rotation

    // Let's define the rotated request

    // For round-robin:
    //   rotated_req[i] = request[(i - (last_granted_port + 1)) mod PORTS]
    //   But we want to rotate left, so:
    //   rotated_req[i] = request[(i + last_granted_port + 1) mod PORTS]

    // Actually, let's think about this more carefully.

    // In round-robin, after granting port P, the next highest priority should be P+1, then P+2, etc.
    // So we want to rotate the request vector so that port P+1 is at position 0 (highest priority for LSB)
    // or at the highest position (for MSB priority).

    // Let's say we use LSB high priority for the rotated vector.
    // Then rotated_req[0] should correspond to port (last_granted_port + 1) mod PORTS
    // rotated_req[1] should correspond to port (last_granted_port + 2) mod PORTS
    // etc.

    // So rotated_req[i] = request[(last_granted_port + 1 + i) mod PORTS]

    // Then we find the lowest set bit in rotated_req, say at position j.
    // The winner in original space is (last_granted_port + 1 + j) mod PORTS.

    // For MSB high priority in the rotated vector:
    // rotated_req[PORTS-1] should correspond to port (last_granted_port + 1) mod PORTS
    // rotated_req[PORTS-2] should correspond to port (last_granted_port + 2) mod PORTS
    // etc.
    // So rotated_req[i] = request[(last_granted_port + 1 + (PORTS-1-i)) mod PORTS]
    // Then we find the highest set bit in rotated_req, say at position j.
    // The winner in original space is (last_granted_port + 1 + (PORTS-1-j)) mod PORTS.

    // This is getting complex. Let's simplify by always using LSB high priority for the internal priority encoder,
    // and handle the MSB case by reversing the request vector before encoding.

    // Actually, let's just implement a priority encoder that can handle both cases.

    // Let's define a function to find the index of the selected bit

    // For LSB high priority:
    //   Find the lowest set bit
    // For MSB high priority:
    //   Find the highest set bit

    // We'll implement this using a priority encoder

    // Let's create a priority encoder module inline

    // For LSB high priority:
    //   mask = req & (~req + 1)
    //   Then encode mask to get index

    // For MSB high priority:
    //   Reverse req, find LSB, then reverse index

    // Let's implement the LSB priority encoder first

    // Function to encode a one-hot vector to binary
    // We'll use a simple approach: for each bit, if it's set, output its index

    // Since we're dealing with a one-hot vector (after masking), we can use a simple encoder

    // Let's define the encoder

    // For a one-hot vector of width PORTS, the encoded value is the index of the set bit

    // We can use a case statement or a series of muxes

    // Let's use a simple approach:
    //   enc = 0
    //   for i = 0 to PORTS-1:
    //       if mask[i]: enc = i

    // But in Verilog, we can't easily do this without a loop

    // Let's use a different approach: use a priority encoder that works on the original request

    // For LSB high priority:
    //   We want the lowest index i such that request[i] is set
    //   This is equivalent to finding the lowest set bit

    // For MSB high priority:
    //   We want the highest index i such that request[i] is set
    //   This is equivalent to finding the highest set bit

    // Let's implement both using a priority encoder

    // For LSB high priority:
    //   We can use the following trick:
    //   mask = request & (~request + 1)
    //   Then the encoded value is the index of the set bit in mask

    // For MSB high priority:
    //   We can reverse the request, apply LSB high priority, then reverse the index

    // Let's implement the LSB high priority encoder

    // First, compute the mask for LSB high priority
    wire [PORTS-1:0] lsb_mask;
    assign lsb_mask = request & (~request + 1'b1);

    // Now encode lsb_mask to get the index
    // We'll use a simple encoder

    // For a one-hot vector, we can use a series of muxes
    // enc = 0
    // if lsb_mask[1]: enc = 1
    // if lsb_mask[2]: enc = 2
    // etc.

    // Let's define the encoder using a case statement

    // But since PORTS is a parameter, we need to handle it generically

    // Let's use a different approach: use a priority encoder that works on the original request

    // For LSB high priority:
    //   We want the lowest index i such that request[i] is set
    //   We can use the following:
    //   For i from 0 to PORTS-1:
    //       if request[i] is set and all lower bits are not set, then i is the winner

    // This is equivalent to:
    //   winner = i if request[i] & ~(request[i-1:0])

    // Let's implement this

    // For LSB high priority:
    //   winner_mask[i] = request[i] & ~(request[i-1:0])
    //   Then the encoded value is the index of the set bit in winner_mask

    // For MSB high priority:
    //   winner_mask[i] = request[i] & ~(request[PORTS-1:i+1])
    //   Then the encoded value is the index of the set bit in winner_mask

    // Let's implement both

    // First, let's define the winner mask for LSB high priority
    wire [PORTS-1:0] lsb_winner_mask;
    genvar i;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : lsb_gen
            if (i == 0) begin : lsb_base
                assign lsb_winner_mask[i] = request[i];
            end else begin : lsb_other
                assign lsb_winner_mask[i] = request[i] & ~(request[i-1:0]);
            end
        end
    endgenerate

    // Now encode lsb_winner_mask to get the index
    // We'll use a simple encoder

    // For a one-hot vector, we can use a series of muxes
    // Let's define the encoder

    // We'll use a function to encode a one-hot vector

    // Function to encode a one-hot vector of width PORTS to ENC_WIDTH bits
    // We'll use a case statement

    // But since we're in a generate block, we can't easily use a function

    // Let's use a different approach: use a priority encoder that works on the original request

    // Actually, let's just use a simple encoder using a series of muxes

    // For LSB high priority:
    //   enc = 0
    //   if lsb_winner_mask[1]: enc = 1
    //   if lsb_winner_mask[2]: enc = 2
    //   etc.

    // Let's define the encoder using a case statement

    // We'll use a function

    // Function to encode a one-hot vector
    function [ENC_WIDTH-1:0] encode_one_hot;
        input [PORTS-1:0] vec;
        integer j;
        begin
            encode_one_hot = 0;
            for (j = 0; j < PORTS; j = j + 1) begin
                if (vec[j]) begin
                    encode_one_hot = j[ENC_WIDTH-1:0];
                end
            end
        end
    endfunction

    // Now we can use this function to encode the winner mask

    // For LSB high priority:
    wire [ENC_WIDTH-1:0] lsb_encoded;
    assign lsb_encoded = encode_one_hot(lsb_winner_mask);

    // For MSB high priority:
    //   winner_mask[i] = request[i] & ~(request[PORTS-1:i+1])
    wire [PORTS-1:0] msb_winner_mask;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : msb_gen
            if (i == PORTS-1) begin : msb_top
                assign msb_winner_mask[i] = request[i];
            end else begin : msb_other
                assign msb_winner_mask[i] = request[i] & ~(request[PORTS-1:i+1]);
            end
        end
    endgenerate

    wire [ENC_WIDTH-1:0] msb_encoded;
    assign msb_encoded = encode_one_hot(msb_winner_mask);

    // Now select the encoded value based on ARB_LSB_HIGH_PRIORITY
    wire [ENC_WIDTH-1:0] fixed_encoded;
    assign fixed_encoded = ARB_LSB_HIGH_PRIORITY ? lsb_encoded : msb_encoded;

    // Now handle round-robin
    // For round-robin, we need to rotate the request vector

    // Let's compute the rotated request for round-robin
    // rotated_req[i] = request[(last_granted_port + 1 + i) mod PORTS] for LSB high priority
    // rotated_req[i] = request[(last_granted_port + 1 + (PORTS-1-i)) mod PORTS] for MSB high priority

    // Let's define the rotated request

    // For round-robin, we'll use the same priority encoder but on the rotated request

    // Let's compute the rotated request for LSB high priority
    wire [PORTS-1:0] rotated_req_lsb;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : rot_lsb_gen
            assign rotated_req_lsb[i] = request[(last_granted_port + 1 + i) % PORTS];
        end
    endgenerate

    // For round-robin, we'll use the same priority encoder but on the rotated request
    // For LSB high priority:
    wire [PORTS-1:0] rot_lsb_winner_mask;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : rot_lsb_gen2
            if (i == 0) begin : rot_lsb_base
                assign rot_lsb_winner_mask[i] = rotated_req_lsb[i];
            end else begin : rot_lsb_other
                assign rot_lsb_winner_mask[i] = rotated_req_lsb[i] & ~(rotated_req_lsb[i-1:0]);
            end
        end
    endgenerate

    wire [ENC_WIDTH-1:0] rot_lsb_encoded;
    assign rot_lsb_encoded = encode_one_hot(rot_lsb_winner_mask);

    // The winner in original space is (last_granted_port + 1 + rot_lsb_encoded) mod PORTS
    wire [ENC_WIDTH-1:0] rr_lsb_winner;
    assign rr_lsb_winner = (last_granted_port + 1 + rot_lsb_encoded) % PORTS;

    // For MSB high priority:
    wire [PORTS-1:0] rotated_req_msb;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : rot_msb_gen
            assign rotated_req_msb[i] = request[(last_granted_port + 1 + (PORTS-1-i)) % PORTS];
        end
    endgenerate

    wire [PORTS-1:0] rot_msb_winner_mask;
    generate
        for (i = 0; i < PORTS; i = i + 1) begin : rot_msb_gen2
            if (i == PORTS-1) begin : rot_msb_top
                assign rot_msb_winner_mask[i] = rotated_req_msb[i];
            end else begin : rot_msb_other
                assign rot_msb_winner_mask[i] = rotated_req_msb[i] & ~(rotated_req_msb[PORTS-1:i+1]);
            end
        end
    endgenerate

    wire [ENC_WIDTH-1:0] rot_msb_encoded;
    assign rot_msb_encoded = encode_one_hot(rot_msb_winner_mask);

    // The winner in original space is (last_granted_port + 1 + (PORTS-1-rot_msb_encoded)) mod PORTS
    wire [ENC_WIDTH-1:0] rr_msb_winner;
    assign rr_msb_winner = (last_granted_port + 1 + (PORTS-1-rot_msb_encoded)) % PORTS;

    // Now select the winner based on ARB_TYPE_ROUND_ROBIN and ARB_LSB_HIGH_PRIORITY
    wire [ENC_WIDTH-1:0] winner_idx;
    assign winner_idx = ARB_TYPE_ROUND_ROBIN ? 
        (ARB_LSB_HIGH_PRIORITY ? rr_lsb_winner : rr_msb_winner) : 
        fixed_encoded;

    // Now create the one-hot grant vector
    wire [PORTS-1:0] grant_one_hot;
    genvar k;
    generate
        for (k = 0; k < PORTS; k = k + 1) begin : grant_gen
            assign grant_one_hot[k] = (winner_idx == k[ENC_WIDTH-1:0]) & |request;
        end
    endgenerate

    // Now handle blocking
    // If ARB_BLOCK is set, hold the grant until acknowledge or request drops

    // Let's define the blocking logic

    // If ARB_BLOCK is set:
    //   If blocked_valid is set, hold the grant
    //   Otherwise, use the raw grant

    // If ARB_BLOCK_ACK is set:
    //   Release the block when acknowledge is set
    // Else:
    //   Release the block when request drops

    // Let's implement the blocking logic

    // First, let's define the raw grant
    assign raw_grant = grant_one_hot;
    assign raw_valid = |request;
    assign raw_encoded = winner_idx;

    // Now handle blocking
    // If ARB_BLOCK is set, we need to hold the grant

    // Let's define the blocking state

    // If ARB_BLOCK is set:
    //   If blocked_valid is set, output the blocked grant
    //   Otherwise, output the raw grant

    // If ARB_BLOCK is not set:
    //   Output the raw grant

    // Let's implement the blocking logic

    // First, let's define the condition to set the block
    // Set the block when a grant is issued and ARB_BLOCK is set

    // Let's define the condition to clear the block
    // If ARB_BLOCK_ACK is set: clear when acknowledge is set
    // Else: clear when request drops

    // Let's implement the blocking logic

    // If ARB_BLOCK is set:
    //   If blocked_valid is set:
    //       If ARB_BLOCK_ACK is set:
    //           If acknowledge is set, clear the block
    //       Else:
    //           If request drops, clear the block
    //   Else:
    //       If raw_valid is set, set the block

    // Let's implement this

    // First, let's define the condition to set the block
    wire set_block;
    assign set_block = ARB_BLOCK & ~blocked_valid & raw_valid;

    // Now define the condition to clear the block
    wire clear_block;
    assign clear_block = ARB_BLOCK & blocked_valid & 
        (ARB_BLOCK_ACK ? (|acknowledge) : (~(|request)));

    // Now update the blocked state
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blocked_valid <= 1'b0;
            blocked_grant <= {PORTS{1'b0}};
            last_granted_port <= {ENC_WIDTH{1'b0}};
        end else begin
            if (set_block) begin
                blocked_valid <= 1'b1;
                blocked_grant <= raw_grant;
                last_granted_port <= winner_idx;
            end else if (clear_block) begin
                blocked_valid <= 1'b0;
                blocked_grant <= {PORTS{1'b0}};
            end
        end
    end

    // Now output the final grant
    // If ARB_BLOCK is set and blocked_valid is set, output the blocked grant
    // Otherwise, output the raw grant

    assign grant = (ARB_BLOCK & blocked_valid) ? blocked_grant : raw_grant;
    assign grant_valid = (ARB_BLOCK & blocked_valid) ? 1'b1 : raw_valid;
    assign grant_encoded = (ARB_BLOCK & blocked_valid) ? 
        encode_one_hot(blocked_grant) : raw_encoded;

endmodule
