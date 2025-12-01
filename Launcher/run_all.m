for i = 0:100
    for R = [5,10,15]
        for C = [3,6,9]
            task = ['random_R',num2str(R),'_C',num2str(C)];
            disp(task)
            disp(i)
            run(task)
            close all
        end
    end
end