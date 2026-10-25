// A compact journal sheet. Native radios keep touch and keyboard selection consistent.
function recordChoices(name, values, selected) {
 return values.map(value=>`<label class="record-choice"><input type="radio" name="${name}" value="${esc(value)}" ${value===selected?'checked':''} required><span>${esc(value==='複数箇所（メモに記入）'?'複数箇所':value)}</span></label>`).join('');
}
function openRecord() {
 const date=weekDates()[selectedDay].key;
 const existing=state.records.find(r=>r.date===date);
 if(document.querySelector('.product-sheet'))closeModal();
 sheetReturnFocus=document.activeElement;
 sheetPreviousOverflow=document.body.style.overflow;
 document.body.style.overflow='hidden';
 document.querySelector('.shell').inert=true;
 document.getElementById('overlay').innerHTML=`<div class="modal-backdrop product-sheet-backdrop" onclick="if(event.target===this)closeModal()"><section class="product-sheet record-sheet" role="dialog" aria-modal="true" aria-labelledby="record-title"><div class="sheet-top"><div class="sheet-grab" onpointerdown="startProductSheetDrag(event)" onpointermove="moveProductSheetDrag(event)" onpointerup="endProductSheetDrag(event)" onpointercancel="endProductSheetDrag(event)" aria-hidden="true"><span></span></div><button class="sheet-close" onclick="closeModal()" aria-label="閉じる">×</button></div><header class="record-header"><span>SKIN JOURNAL</span><h2 id="record-title" tabindex="-1">${existing?'肌の記録を編集':'肌を記録する'}</h2><p>今日の調子を、ひとつずつ。</p></header><form class="record-form" onsubmit="addRecord(event)"><div class="product-sheet-scroll record-scroll"><div class="record-date field"><label for="record-date">日付</label><input id="record-date" type="date" name="date" value="${date}" max="${journalToday()}" required></div><fieldset class="record-section"><legend>肌の調子</legend><div class="record-choices mood-choices">${recordChoices('mood',['良い','ふつう','ゆらぎ気味','乾燥が気になる'],existing?.mood||'ふつう')}</div></fieldset><div class="record-section record-sleep"><div><label for="record-sleep">昨夜の睡眠</label><small>0.5時間ずつ調整できます</small></div><div class="sleep-stepper"><button type="button" onclick="adjustRecordSleep(-0.5)" aria-label="睡眠を0.5時間減らす">−</button><div><input id="record-sleep" type="number" inputmode="decimal" name="sleep" min="0" max="24" step="0.5" value="${esc(existing?.sleep??7)}" required aria-label="睡眠時間"><span>時間</span></div><button type="button" onclick="adjustRecordSleep(0.5)" aria-label="睡眠を0.5時間増やす">＋</button></div></div><fieldset class="record-section"><legend>スキンケアはできた？</legend><div class="record-choices mood-choices">${recordChoices('care',['できた','一部できた','お休み','未記録'],existing?.care||'未記録')}</div></fieldset><section class="record-section acne-section" aria-labelledby="acne-title"><div class="acne-heading"><h3 id="acne-title">ニキビの記録</h3><button type="button" onclick="clearAcneSpots()">なしにする</button></div><p class="acne-help">顔をタップして追加。印を選んで状態を記録できます。</p><div id="acne-workspace"></div></section><div class="record-section record-notes"><div class="field"><label for="record-memo">肌のメモ <span>任意</span></label><textarea id="record-memo" name="memo" maxlength="1000" rows="3" placeholder="乾燥、気になった変化、使ったアイテムなど">${esc(existing?.memo||'')}</textarea></div><div class="field"><label for="record-treatment">美容施術 <span>任意</span></label><input id="record-treatment" name="treatment" value="${esc(existing?.treatment||'')}" placeholder="施術名・クリニック・経過など" maxlength="150"></div></div></div><footer class="record-footer"><button class="btn primary" type="submit">${icon('check')} 記録を保存する</button></footer></form></section></div>`;
 initAcneDraft(existing);
 document.getElementById('record-title').focus({preventScroll:true});
 document.getElementById('record-date').addEventListener('change',event=>loadRecordDate(event.target.value));
}
function adjustRecordSleep(delta){const input=document.getElementById('record-sleep');input.value=Math.min(24,Math.max(0,(Number(input.value)||0)+delta));}
function loadRecordDate(date){
 const form=document.querySelector('.record-form'),record=state.records.find(r=>r.date===date);
 form.elements.sleep.value=record?.sleep??7;
 form.elements.mood.value=record?.mood||'ふつう';
 form.elements.care.value=record?.care||'未記録';
 initAcneDraft(record);
 form.elements.memo.value=record?.memo||'';
 form.elements.treatment.value=record?.treatment||'';
 document.getElementById('record-title').textContent=record?'肌の記録を編集':'肌を記録する';
}
// Persist before dismissing so a storage failure leaves the entered record available.
function addRecord(event){
 event.preventDefault();
 const form=event.target;
 if(!form.reportValidity())return;
 const record=Object.fromEntries(new FormData(form));
 delete record['spot-status'];
 if(!validJournalDate(record.date)){toast('今日までの日付を選んでください');return;}
 if(acneDraft.spots.some(spot=>!acneStatuses[spot.status])){toast('それぞれのニキビの状態を選んでください');return;}
 record.acneSpots=acneDraft.spots.map(spot=>({...spot}));
 record.acne=acneDraft.spots.length?acneDraft.spots.map(spot=>`${spot.area}（${acneStatuses[spot.status]}）`).join('、'):(acneDraft.legacy||'なし');
 const records=[...state.records.filter(r=>r.date!==record.date),record].sort((a,b)=>b.date.localeCompare(a.date));
 try{localStorage.setItem('skins-demo-v1',JSON.stringify({...state,records}));}
 catch{toast('保存できませんでした。空き容量をご確認ください。');return;}
 state.records=records;
 if(typeof journalSelected!=='undefined'){journalSelected=record.date;journalMonth=record.date.slice(0,7);}
 closeModal();render();toast('肌の記録を保存しました');
}

const acneStatuses={new:'新しくできた',worse:'悪化した',better:'良くなってきた'};
let acneDraft={spots:[],legacy:''},activeAcneId=null;
function initAcneDraft(record){
 acneDraft={spots:(record?.acneSpots||[]).map(s=>({...s})),legacy:!record?.acneSpots?.length&&record?.acne!=='なし'?(record?.acne||''):''};
 activeAcneId=acneDraft.spots[0]?.id||null;
 renderAcneMap();
}
function acneArea(x,y){if(y<34)return 'おでこ';if(y>79)return 'あご';if(y>69&&(x<30||x>70))return 'フェイスライン';if(x>40&&x<60)return '鼻';return x<50?'右頬':'左頬';}
function acneFaceSvg(){return `<svg viewBox="0 0 240 280" aria-hidden="true"><path d="M83 232v29m74-29v29M49 279q16-21 34-23m74 0q18 2 34 23" fill="none" stroke="#c5d1dd" stroke-width="2"/><ellipse cx="38" cy="133" rx="9" ry="20" fill="#f0f4f8" stroke="#c5d1dd"/><ellipse cx="202" cy="133" rx="9" ry="20" fill="#f0f4f8" stroke="#c5d1dd"/><path d="M120 18C67 18 40 52 41 103l8 65c5 39 44 79 71 79s66-40 71-79l8-65c1-51-26-85-79-85Z" fill="#f3f6fa" stroke="#b8c8d8" stroke-width="2"/><path d="M66 101q16-9 31-2m46 0q15-7 31 2M69 120q12 7 25 0m52 0q13 7 25 0M120 126l-5 28q5 5 12 0M103 185q17 8 34 0" fill="none" stroke="#adbdce" stroke-width="2" stroke-linecap="round"/><path d="M120 192v3" stroke="#d3dde7" stroke-width="2"/></svg>`;}
function renderAcneMap(){
 const root=document.getElementById('acne-workspace');if(!root)return;
 const active=acneDraft.spots.find(s=>s.id===activeAcneId);
 root.innerHTML=`<div class="face-orientation"><span>自分の右</span><span>自分の左</span></div><div class="acne-map" onclick="addAcneSpot(event)" role="group" aria-label="ニキビを記録する顔の図">${acneFaceSvg()}${acneDraft.spots.map((s,i)=>`<button type="button" class="acne-pin ${s.status||'pending'} ${s.id===activeAcneId?'selected':''}" style="left:${s.x}%;top:${s.y}%" onclick="event.stopPropagation();selectAcneSpot('${s.id}')" aria-label="${i+1}番 ${esc(s.area)} ${acneStatuses[s.status]||'状態未選択'}" aria-pressed="${s.id===activeAcneId}">${i+1}</button>`).join('')}</div><div class="acne-key"><span class="new">新しくできた</span><span class="worse">悪化した</span><span class="better">良くなってきた</span></div>${acneDraft.legacy?`<p class="acne-legacy">以前の記録：${esc(acneDraft.legacy)}<br>顔をタップすると、位置つきの記録に更新できます。</p>`:''}${active?`<div class="acne-editor"><div class="acne-heading"><strong>${acneDraft.spots.indexOf(active)+1} · ${esc(active.area)}</strong><button type="button" onclick="removeAcneSpot('${active.id}')">この印を削除</button></div><fieldset><legend>状態の変化</legend><div class="acne-statuses">${Object.entries(acneStatuses).map(([key,label])=>`<label class="record-choice"><input type="radio" name="spot-status" value="${key}" ${active.status===key?'checked':''} onchange="setAcneStatus('${key}')"><span>${label}</span></label>`).join('')}</div></fieldset></div>`:'<p class="acne-empty">気になる場所に印をつけましょう。</p>'}<div class="acne-actions"><label>場所から追加<select aria-label="ニキビを追加する場所" onchange="addAcneByArea(this.value);this.value='' "><option value="">場所を選ぶ</option>${['おでこ','右頬','左頬','鼻','あご','フェイスライン'].map(a=>`<option>${a}</option>`).join('')}</select></label><button type="button" onclick="carryAcneSpots()">前回の位置を引き継ぐ</button></div>${acneDraft.spots.length?`<div class="acne-spot-list" aria-label="追加したニキビ">${acneDraft.spots.map((s,i)=>`<button type="button" aria-pressed="${s.id===activeAcneId}" onclick="selectAcneSpot('${s.id}')"><span>${i+1} · ${esc(s.area)}</span><small>${acneStatuses[s.status]||'状態を選択'}</small></button>`).join('')}</div>`:''}`;
}
function addAcneSpot(event){if(event.target.closest('button'))return;const box=event.currentTarget.getBoundingClientRect(),x=(event.clientX-box.left)/box.width*100,y=(event.clientY-box.top)/box.height*100;
 // Restrict marks to the face silhouette, excluding the neck and surrounding space.
 if(y<8||y>88||((x-50)/34)**2+((y-46)/42)**2>1)return;
 appendAcneSpot(x,y,acneArea(x,y));
}
function appendAcneSpot(x,y,area){const spot={id:'spot-'+Date.now()+'-'+Math.random().toString(36).slice(2,7),x:Math.round(x*10)/10,y:Math.round(y*10)/10,area,status:'new'};acneDraft.spots.push(spot);acneDraft.legacy='';activeAcneId=spot.id;renderAcneMap();revealAcneSection();}
function selectAcneSpot(id){activeAcneId=id;renderAcneMap();}
function setAcneStatus(status){const spot=acneDraft.spots.find(s=>s.id===activeAcneId);if(spot&&acneStatuses[status]){spot.status=status;renderAcneMap();document.querySelector('.acne-statuses input:checked')?.focus({preventScroll:true});}}
function removeAcneSpot(id){acneDraft.spots=acneDraft.spots.filter(s=>s.id!==id);activeAcneId=acneDraft.spots[0]?.id||null;renderAcneMap();}
function clearAcneSpots(){acneDraft={spots:[],legacy:''};activeAcneId=null;renderAcneMap();}
function addAcneByArea(area){const positions={'おでこ':[50,25],'右頬':[29,57],'左頬':[71,57],'鼻':[50,53],'あご':[50,81],'フェイスライン':[27,71]};if(positions[area])appendAcneSpot(...positions[area],area);}
function carryAcneSpots(){const date=document.getElementById('record-date').value,previous=state.records.filter(r=>r.date<date&&r.acneSpots?.length).sort((a,b)=>b.date.localeCompare(a.date))[0];if(!previous){toast('引き継げる位置の記録がありません');return;}
 const ids=new Set(acneDraft.spots.map(s=>s.id)),added=previous.acneSpots.filter(s=>!ids.has(s.id)).map(s=>({...s,status:''}));
 if(!added.length){toast('前回の位置は追加済みです');return;}
 acneDraft.spots.push(...added);acneDraft.legacy='';activeAcneId=added[0].id;renderAcneMap();toast('今日の状態をひとつずつ選んでください');
}

function revealAcneSection(){const scroll=document.querySelector('.record-scroll'),section=document.querySelector('.acne-section');if(scroll&&section)scroll.scrollTo({top:scroll.scrollTop+section.getBoundingClientRect().top-scroll.getBoundingClientRect().top,behavior:'smooth'});}
