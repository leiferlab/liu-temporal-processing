function code_name = problem_code_lookup(code)
    % looks up the problem given code
    switch code
        case 0
            code_name = 'no error';
        case 1
            code_name = 'head/tail flip';
        case 2
            code_name = 'image score low';
        case 3
            code_name = 'centerline out of body';
        case 4
            code_name = 'displacement score low';
        case 5
            code_name = 'length too short';
        case 6
            code_name = 'length too long';
        case 7
            code_name = 'aspect ratio too small';
        case 8
            code_name = 'aspect ratio too large';
    end
end