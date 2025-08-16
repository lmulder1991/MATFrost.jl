

clear matfrostjuliacall
mh = mexhost();

tops1 = struct("a",double([1]), "b",int64(2),"c",double(3), "d", "wefwwefweagaergaerhergregreg");
tops2 = struct("a",double([1]), "b",int64(2),"c",double(3), "d", "wefwefwefweeagaergaerhergregreg");

nest1 = [struct("a", tops1, "b", tops2); struct("a", tops1, "b", 23); struct("a", tops1, "b", tops1)]; 

s= mh.feval("matfrostjuliacall", ...
    nest1);

nest1 = [struct("a", tops1, "b", tops2); struct("a", tops1, "b", tops2); struct("a", tops1, "b", tops1)]; 

s2= mh.feval("matfrostjuliacall", ...
    nest1);