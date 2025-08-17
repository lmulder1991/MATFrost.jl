

clear matfrostjuliacall
mh = mexhost();

tops1 = struct("a",double([1]), "b",int64(2),"c",double(3), "d", "wefwwefweagaergaerhergregreg");
tops2 = struct("a",double([1]), "b",int64(2),"c",double(3), "d", "wefwefwefweeagaergaerhergregreg");

c = {3.0;int64(3)};
% nest1 = [struct("a", tops1, "b", tops2, "c", c); struct("a", tops1, "b", 23, "c", c); struct("a", tops1, "b", tops1, "c", c)]; 

% struct(a=tops1, b=tops2, c=c)
nest1 = struct;
nest1.a = tops1;
nest1.b = tops2;
nest1.c  = c;

nest1(2,1).a = tops1;
nest1(2,1).b = 23;
nest1(2,1).c  = c;

nest1(3,1).a = tops1;
nest1(3,1).b = tops2;
nest1(3,1).c  = c;

% 
% s= mh.feval("matfrostjuliacall", ...
%     nest1);

namedtupe = struct;
namedtupe.e = int32(353);
namedtupe.f = single(4353.0);

nest1 = struct;
nest1.a = tops1;
nest1.b = tops2;
nest1.c  = c;
nest1.d = namedtupe;

nest1(2,1).a = tops1;
nest1(2,1).b = tops2;
nest1(2,1).c  = c;
nest1(2,1).d = namedtupe;

nest1(3,1).a = tops1;
nest1(3,1).b = tops2;
nest1(3,1).c  = c;
nest1(3,1).d = namedtupe;



s2= mh.feval("matfrostjuliacall", ...
    nest1)