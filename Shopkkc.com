<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>FreeShop — Cửa hàng miễn phí</title>
  <style>
    :root{--accent:#0ea5a4;--bg:#0f172a;--card:#0b1220;--muted:#94a3b8}
    *{box-sizing:border-box;font-family:system-ui,-apple-system,Segoe UI,Roboto,'Helvetica Neue',Arial}
    body{margin:0;background:linear-gradient(180deg,#071029 0%,#071225 100%);color:#e6eef6;min-height:100vh;padding:28px}
    .wrap{max-width:1100px;margin:0 auto}
    header{display:flex;gap:16px;align-items:center;justify-content:space-between;margin-bottom:18px}
    h1{font-size:20px;margin:0}
    .search{flex:1;margin:0 18px}
    .search input{width:100%;padding:10px 12px;border-radius:10px;border:0;background:#071a2b;color:inherit}
    .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:14px}
    .card{background:linear-gradient(180deg,rgba(255,255,255,0.02),transparent);padding:14px;border-radius:12px;border:1px solid rgba(255,255,255,0.03)}
    .thumb{height:140px;border-radius:8px;display:block;background:#021428;background-size:cover;background-position:center;margin-bottom:10px}
    .title{font-weight:600;margin:0 0 6px 0}
    .price{color:var(--accent);font-weight:700}
    .muted{color:var(--muted);font-size:13px}
    .btn{display:inline-block;padding:8px 12px;border-radius:10px;border:0;background:var(--accent);color:#022;cursor:pointer;font-weight:600}
    .btn-ghost{background:transparent;border:1px solid rgba(255,255,255,0.06)}
    .row{display:flex;gap:8px;align-items:center}
    .cart-btn{position:fixed;right:20px;bottom:20px;background:var(--accent);color:#022;padding:14px;border-radius:14px;box-shadow:0 6px 18px rgba(2,6,23,0.6);cursor:pointer}
    .cart-count{background:#022;color:var(--accent);padding:4px 8px;border-radius:999px;margin-left:8px;font-weight:700}
    /* modal */
    .modal{position:fixed;inset:0;display:none;align-items:center;justify-content:center;padding:28px}
    .modal.open{display:flex}
    .modal-card{width:100%;max-width:760px;background:#07172a;border-radius:12px;padding:18px;border:1px solid rgba(255,255,255,0.03)}
    .flex{display:flex;gap:12px}
    .spacer{flex:1}
    footer{margin-top:18px;color:var(--muted);font-size:13px}
    .admin{margin-top:22px;padding:12px;border-radius:10px;background:rgba(255,255,255,0.02)}
    input[type=text],input[type=url],input[type=number]{width:100%;padding:8px;border-radius:8px;border:0;background:#031726;color:inherit}
    label{display:block;font-size:13px;margin-bottom:6px}
    .small{font-size:13px;color:var(--muted)}
    @media (max-width:540px){.thumb{height:120px}}
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <div style="display:flex;gap:12px;align-items:center">
        <img src="data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='36' height='36' viewBox='0 0 24 24'><rect rx='5' width='24' height='24' fill='%230ea5a4'/><text x='12' y='16' font-size='12' text-anchor='middle' fill='%230b1220' font-family='Arial'>FS</text></svg>" alt="logo" style="height:44px;border-radius:10px;">
        <div>
          <h1>FreeShop — Cửa hàng miễn phí</h1>
          <div class="small">Mẫu shop tĩnh, miễn phí, dễ chỉnh sửa</div>
        </div>
      </div>

      <div class="search"><input id="q" placeholder="Tìm sản phẩm..." oninput="renderProducts()"></div>
      <div class="row">
        <button class="btn btn-ghost" id="toggleAdmin" onclick="toggleAdmin()">Mở/Đóng Admin</button>
      </div>
    </header>

    <main>
      <div id="productGrid" class="grid"></div>

      <div class="admin" id="adminPanel" style="display:none">
        <h3 style="margin-top:0">Thêm sản phẩm (admin)</h3>
        <div style="display:grid;grid-template-columns:1fr 140px;gap:10px;align-items:end">
          <div>
            <label for="pname">Tên</label>
            <input id="pname" type="text" placeholder="Tên sản phẩm">
            <label for="pdesc">Mô tả</label>
            <input id="pdesc" type="text" placeholder="Mô tả ngắn">
            <label for="pprice">Giá (VND)</label>
            <input id="pprice" type="number" placeholder="10000">
            <label for="pimg">Ảnh (URL)</label>
            <input id="pimg" type="url" placeholder="https://...jpg">
          </div>
          <div>
            <button class="btn" onclick="addProductFromForm()">Thêm vào shop</button>
            <div style="height:10px"></div>
            <button class="btn btn-ghost" onclick="exportProducts()">Tải JSON sản phẩm</button>
            <div style="height:10px"></div>
            <button class="btn btn-ghost" onclick="importDefault()">Load mẫu</button>
          </div>
        </div>
        <div style="margin-top:10px" class="small">Lưu ý: file này chạy hoàn toàn trên máy bạn. Để bán thật sự cần tích hợp cổng thanh toán (momo/zalopay/paypal) và backend.</div>
      </div>

    </main>

    <footer>
      <div>Muốn mình deploy lên GitHub Pages/Netlify miễn phí? Chọn "Có" — mình sẽ hướng dẫn tiếp.</div>
    </footer>
  </div>

  <button class="cart-btn" onclick="openCart()">Giỏ hàng <span id="count" class="cart-count">0</span></button>

  <div id="cartModal" class="modal" onclick="if(event.target===this)closeCart()">
    <div class="modal-card">
      <div class="flex">
        <h3>Giỏ hàng</h3>
        <div class="spacer"></div>
        <button class="btn btn-ghost" onclick="closeCart()">Đóng</button>
      </div>
      <div id="cartItems" style="margin-top:12px"></div>
      <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center">
        <div class="small">Tổng</div>
        <div id="total" style="font-weight:800"></div>
      </div>
      <div style="margin-top:12px;display:flex;gap:8px">
        <button class="btn" onclick="checkout()">Thanh toán (mẫu)</button>
        <button class="btn btn-ghost" onclick="exportCart()">Tải giỏ hàng (JSON)</button>
      </div>
    </div>
  </div>

  <script>
    // Dữ liệu mẫu
    let products = []
    let cart = []

    function defaultProducts(){
      return [
        {id:1,name:'Gift Card 50K',desc:'Thẻ quà tặng 50.000 VND',price:50000,img:'https://images.unsplash.com/photo-1602526431065-9d1a4a2d0a63?auto=format&fit=crop&w=800&q=60'},
        {id:2,name:'Skin bộ đỏ',desc:'Skin VIP',price:120000,img:'https://images.unsplash.com/photo-1602524209426-4b3a0f3b4a2c?auto=format&fit=crop&w=800&q=60'},
        {id:3,name:'Kim cương 100',desc:'Gói 100 kim cương',price:250000,img:'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=60'}
      ]
    }

    function renderProducts(){
      const q = document.getElementById('q').value.trim().toLowerCase()
      const grid = document.getElementById('productGrid')
      grid.innerHTML=''
      products.filter(p=>p.name.toLowerCase().includes(q)||p.desc.toLowerCase().includes(q)).forEach(p=>{
        const el = document.createElement('div');el.className='card'
        el.innerHTML = `
          <div class="thumb" style="background-image:url('${p.img}')"></div>
          <div class="title">${escapeHtml(p.name)}</div>
          <div class="small muted">${escapeHtml(p.desc)}</div>
          <div style="margin-top:10px;display:flex;justify-content:space-between;align-items:center">
            <div class="price">${formatPrice(p.price)}</div>
            <div>
              <button class="btn btn-ghost" onclick='viewDetail(${p.id})'>Xem</button>
              <button class="btn" onclick='addToCart(${p.id})'>Thêm</button>
            </div>
          </div>
        `
        grid.appendChild(el)
      })
    }

    function viewDetail(id){
      const p = products.find(x=>x.id===id)
      if(!p) return
      const modal = document.getElementById('cartModal')
      modal.classList.add('open')
      document.getElementById('cartItems').innerHTML = `
        <div style="display:flex;gap:12px;align-items:center">
          <div style="width:120px;height:120px;background-image:url('${p.img}');background-size:cover;background-position:center;border-radius:8px"></div>
          <div>
            <div style="font-weight:700">${escapeHtml(p.name)}</div>
            <div class="small muted">${escapeHtml(p.desc)}</div>
            <div style="margin-top:8px;font-weight:800">${formatPrice(p.price)}</div>
            <div style="margin-top:10px"><button class="btn" onclick='addToCart(${p.id}); closeCart();'>Thêm vào giỏ</button></div>
          </div>
        </div>
      `
      document.getElementById('total').innerText = formatPrice(p.price)
    }

    function addToCart(id){
      const p = products.find(x=>x.id===id); if(!p) return
      const existing = cart.find(c=>c.id===id)
      if(existing) existing.qty++
      else cart.push({id:p.id,name:p.name,price:p.price,qty:1})
      saveCart(); updateCount(); toast('Đã thêm: '+p.name)
    }

    function updateCount(){ document.getElementById('count').innerText = cart.reduce((s,c)=>s+c.qty,0) }

    function openCart(){
      const modal = document.getElementById('cartModal')
      modal.classList.add('open')
      renderCartItems()
    }
    function closeCart(){document.getElementById('cartModal').classList.remove('open')}

    function renderCartItems(){
      const container = document.getElementById('cartItems')
      if(cart.length===0) {container.innerHTML='<div class="small">Giỏ hàng trống</div>'; document.getElementById('total').innerText='0 VND'; return}
      container.innerHTML=''
      cart.forEach(item=>{
        const div = document.createElement('div'); div.style.display='flex'; div.style.justifyContent='space-between'; div.style.alignItems='center'; div.style.marginTop='8px'
        div.innerHTML = `<div><div style="font-weight:700">${escapeHtml(item.name)}</div><div class="small muted">Số lượng: ${item.qty}</div></div><div style="text-align:right"><div style="font-weight:800">${formatPrice(item.price*item.qty)}</div><div style="margin-top:6px"><button class='btn btn-ghost' onclick='dec(${item.id})'>-</button> <button class='btn' onclick='inc(${item.id})'>+</button></div></div>`
        container.appendChild(div)
      })
      document.getElementById('total').innerText = formatPrice(cart.reduce((s,i)=>s+i.price*i.qty,0))
    }

    function inc(id){ const it = cart.find(x=>x.id===id); if(it){it.qty++; saveCart(); renderCartItems(); updateCount()} }
    function dec(id){ const it = cart.find(x=>x.id===id); if(it){it.qty--; if(it.qty<=0) cart = cart.filter(x=>x.id!==id); saveCart(); renderCartItems(); updateCount()} }

    function checkout(){
      if(cart.length===0){toast('Giỏ hàng rỗng'); return}
      // MẪU: chỉ hiển thị tóm tắt. Để tích hợp thật, cần backend + cổng thanh toán.
      const payload = {time:new Date().toISOString(),items:cart,total:cart.reduce((s,i)=>s+i.price*i.qty,0)}
      alert('Mẫu checkout — dữ liệu sau có thể gửi lên server:\n'+JSON.stringify(payload,null,2))
    }

    function saveCart(){ localStorage.setItem('fshop_cart',JSON.stringify(cart)) }
    function loadCart(){ try{cart = JSON.parse(localStorage.getItem('fshop_cart')||'[]')}catch(e){cart=[]} updateCount() }

    function addProductFromForm(){
      const name=document.getElementById('pname').value.trim(); if(!name){toast('Nhập tên');return}
      const desc=document.getElementById('pdesc').value.trim()||''
      const price=parseInt(document.getElementById('pprice').value)||0
      const img=document.getElementById('pimg').value.trim()||'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&w=800&q=60'
      const id = products.length?Math.max(...products.map(p=>p.id))+1:1
      products.push({id,name,desc,price,img})
      renderProducts(); toast('Đã thêm sản phẩm')
    }

    function exportProducts(){ const data = JSON.stringify(products,null,2); downloadFile('products.json',data) }
    function exportCart(){ const data = JSON.stringify(cart,null,2); downloadFile('cart.json',data) }
    function downloadFile(name,content){ const a=document.createElement('a'); a.href='data:application/json;charset=utf-8,'+encodeURIComponent(content); a.download=name; a.click(); }

    function importDefault(){ products = defaultProducts(); renderProducts(); toast('Đã load mẫu') }

    function toggleAdmin(){ const el = document.getElementById('adminPanel'); el.style.display = el.style.display==='none'?'block':'none' }

    // tiny helpers
    function formatPrice(n){ if(!n) return '0 VND'; return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g,",")+ ' VND' }
    function escapeHtml(s){ return String(s).replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":"&#39;"})[c]) }
    function toast(t){ console.log('toast',t); /* cheap toast */ const el=document.createElement('div'); el.innerText=t; el.style.position='fixed'; el.style.left='50%'; el.style.transform='translateX(-50%)'; el.style.bottom='100px'; el.style.background='rgba(10,10,12,0.9)'; el.style.padding='8px 12px'; el.style.borderRadius='8px'; el.style.zIndex=9999; document.body.appendChild(el); setTimeout(()=>el.remove(),2000) }

    // init
    (function(){ if(!localStorage.getItem('fshop_products')){ products = defaultProducts(); localStorage.setItem('fshop_products',JSON.stringify(products)) } else { try{products = JSON.parse(localStorage.getItem('fshop_products')||'[]')}catch(e){products=defaultProducts()} }
      renderProducts(); loadCart();
      // save products when user leaves
      window.addEventListener('beforeunload',()=> localStorage.setItem('fshop_products',JSON.stringify(products)))
    })()
  </script>
</body>
</html>
