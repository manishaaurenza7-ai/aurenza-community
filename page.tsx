 "use client";
import Link from 'next/link';
import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function Register() {
  const [name,setName]=useState(''); const [username,setUsername]=useState(''); const [email,setEmail]=useState(''); const [password,setPassword]=useState(''); const [bio,setBio]=useState(''); const [busy,setBusy]=useState(false); const [message,setMessage]=useState('');
  async function submit(e:React.FormEvent){e.preventDefault();setBusy(true);setMessage('');
    const supabase=createClient();
    const {data,error}=await supabase.auth.signUp({email,password,options:{data:{full_name:name,username,bio}}});
    if(error){setMessage(error.message);setBusy(false);return;}
    // A database trigger creates the pending profile from auth user metadata.
    // Do not upsert from the browser: approval fields must remain admin-controlled.
    setMessage('Your registration has been received. Please verify your email if prompted. An administrator must approve your membership before you can access community features.');setBusy(false);
  }
  return <main className="grid min-h-screen place-items-center px-5 py-12"><div className="w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-8 shadow-xl shadow-slate-900/5"><Link href="/" className="text-sm font-semibold text-brand">← Aurenza Academy</Link><h1 className="mt-6 text-3xl font-bold text-ink">Request membership</h1><p className="mt-2 text-sm leading-6 text-slate-600">Create your account. Your application will remain pending until approved by an administrator.</p><form onSubmit={submit} className="mt-7 space-y-4">
    <Field label="Full name"><input required value={name} onChange={e=>setName(e.target.value)} className={input}/></Field>
    <Field label="Username"><input required minLength={3} maxLength={24} pattern="[A-Za-z0-9_]+" value={username} onChange={e=>setUsername(e.target.value)} className={input} placeholder="e.g. alex_kumar"/><small className="text-slate-500">3–24 letters, numbers or underscores.</small></Field>
    <Field label="Email address"><input required type="email" value={email} onChange={e=>setEmail(e.target.value)} className={input}/></Field>
    <Field label="Password"><input required type="password" minLength={8} value={password} onChange={e=>setPassword(e.target.value)} className={input}/></Field>
    <Field label="Short professional bio (optional)"><textarea value={bio} onChange={e=>setBio(e.target.value)} maxLength={240} rows={3} className={input}/></Field>
    <p className="text-xs leading-5 text-slate-500">We do not ask for your phone number. Your email is used for account access and is not displayed on your public profile.</p>
    <button disabled={busy} className="w-full rounded-xl bg-brand px-5 py-3.5 font-semibold text-white disabled:opacity-60">{busy?'Submitting…':'Submit membership request'}</button>
    {message&&<p role="status" className="rounded-xl bg-blue-50 p-4 text-sm leading-6 text-brand">{message}</p>}
  </form><p className="mt-6 text-center text-sm text-slate-600">Already a member? <Link href="/login" className="font-semibold text-brand">Sign in</Link></p></div></main>
}
function Field({label,children}:{label:string;children:React.ReactNode}){return <label className="block space-y-2"><span className="text-sm font-semibold text-ink">{label}</span>{children}</label>}
const input='w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand focus:ring-2 focus:ring-blue-100';
