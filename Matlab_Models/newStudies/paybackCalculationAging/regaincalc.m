clc
%for index1 = 1:8 
    for index2 = 1:20
        %for index3 = 1:15
         bestrevenue(index2)=max(max(inv.regain(:,index2,:,end)));            
        %end
    end
%end 
A = (inv.regain == bestrevenue);

for index1 = 1:8 

end

for i=1:8
plot (squeeze(inv.regain(i,20,5,:)))
hold on
end

[ErId, PVId, BESId] = find(A);

