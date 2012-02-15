function VI = RoomInterpolate(Rm,V,ipoint)
%ROOMINTERPOLATE Interpolates values between points in a 3-d scalar field 
%   ROOMINTERPOLATE first checks the size of the raw data, to ascertain
%   whether the first coordinate is at the first in-room node or the first
%   virtual node. Then interp3 is called to find the interpolated value at
%   the point requested.
%
%   Rm is the Room object
%   V is the field you want to interpolate values inside.
%   ipoint is an array of the coordinates [X Y Z] to interpolate at
%
%   Note: ROOMINTERPOLATE also works for sets of coordinates 
%   [X1 Y1 Z1; X2 Y2 Z2; etc.]

res = Rm.Resolution;
dims = Rm.Dimensions;
if isequal(size(V),dims/res)
    X = res/2:res:dims(1)-res/2;
    Y = res/2:res:dims(2)-res/2;
    Z = res/2:res:dims(3)-res/2;
else
    X = -res/2:res:dims(1)+res/2;
    Y = -res/2:res:dims(2)+res/2;
    Z = -res/2:res:dims(3)+res/2;
end
VI = interp3(X,Y,Z,permute(V,[2 1 3]),ipoint(:,1),ipoint(:,2),ipoint(:,3));